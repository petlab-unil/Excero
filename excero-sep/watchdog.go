package main

import (
	"bufio"
	"cloud.google.com/go/firestore"
	"context"
	"database/sql"
	"firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"fmt"
	"github.com/go-sql-driver/mysql"
	"github.com/google/uuid"
	"github.com/sashabaranov/go-openai"
	"google.golang.org/api/option"
	"log"
	"math"
	"math/rand"
	"os"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"
)

type SimulatedPeerStepRecord struct {
	id    int
	steps int
	start time.Time
	end   time.Time
}

type FirebaseMessage struct {
	content    string
	created    time.Time
	senderId   string
	senderName string
}

type Conversation struct {
	id     int
	uuid   string
	userId int
	sepId  int
}

type FirebaseMessagingRequest struct {
	conversation *Conversation
	prompt       string
	userToken    string
}

func checkFileExists(filename string) bool {
	info, err := os.Stat(filename)
	if os.IsNotExist(err) {
		return false
	}
	return !info.IsDir()
}

func logOutput(sepID int, prompts []openai.ChatCompletionMessage) {
	_, err := os.Stat("logs")
	if os.IsNotExist(err) {
		os.Mkdir("logs", 0750)
	}
	filePath := "logs/sep_output_" + strconv.Itoa(sepID) + ".txt"
	if !checkFileExists(filePath) {
		f, err := os.Create(filePath)
		if err != nil {
			panic(err)
		}
		f.Close()
	}
	f, err := os.OpenFile(filePath, os.O_APPEND|os.O_WRONLY, 0640)
	if err != nil {
		panic(err)
	}
	data := "--------->" + time.Now().Format("2006-01-02 15:04:05") + "\n"
	for _, prompt := range prompts {
		data = data + prompt.Role + "\n"
		data = data + prompt.Content + "\n"
	}
	w := bufio.NewWriter(f)
	_, err = w.WriteString(data)
	if err != nil {
		panic(err)
	}
	w.Flush()
	f.Close()
}

func openAIRequest(prompts []openai.ChatCompletionMessage) string {
	client := openai.NewClient(os.Getenv("OPENAI_API_KEY"))
	resp, err := client.CreateChatCompletion(
		context.Background(),
		openai.ChatCompletionRequest{
			Model:    os.Getenv("OPENAI_MODEL"),
			Messages: prompts,
		},
	)
	if err != nil {
		panic(err)
	}

	return resp.Choices[0].Message.Content
}

func generateProactiveMessage(sepID int, prompt string) string {
	prompts := []openai.ChatCompletionMessage{
		{
			Role:    openai.ChatMessageRoleSystem,
			Content: prompt,
		},
	}
	sepChannel := make(chan string)
	go func(prompts []openai.ChatCompletionMessage, result chan<- string) {
		result <- openAIRequest(prompts)
	}(prompts, sepChannel)
	var message string
	message = <-sepChannel
	return message
}

func setupFirebaseApp(keypath string) (*firebase.App, error) {
	opts := option.WithCredentialsFile(keypath)
	app, err := firebase.NewApp(context.Background(), nil, opts)
	return app, err
}

func setupFCMClient(app *firebase.App) *messaging.Client {
	ctx := context.Background()
	client, err := app.Messaging(ctx)
	if err != nil {
		log.Printf("Error getting Messaging client: %v\n", err)
	}
	return client
}

func saveFBMessage(app *firebase.App, message string, conversationUUID string) {
	client, _ := app.Firestore(context.Background())
	uuidValue := uuid.MustParse(conversationUUID)
	_, _, err := client.Collection("discussions").Doc(uuidValue.String()).Collection("message-feed").Add(
		context.Background(), map[string]interface{}{
			"content":    message,
			"created":    firestore.ServerTimestamp,
			"senderId":   "Alex",
			"senderName": "SEP",
		})
	if err != nil {
		log.Printf("Error getting Messaging client: %v\n", err)
	}
}

func sendFCMMessageToUser(message string, userToken string, client *messaging.Client) {
	if client == nil {
		return
	}
	msg := &messaging.Message{
		Notification: &messaging.Notification{
			Title: "Nouveau Message",
			Body:  fmt.Sprintf("Alex: %s", message),
		},
		Token: userToken,
		Data: map[string]string{
			"has_badge":         "true",
			"notification_type": "chat",
		},
		APNS: &messaging.APNSConfig{
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Sound:            "default",
					ContentAvailable: true,
					MutableContent:   true,
					CustomData: map[string]interface{}{
						"has_badge":         "true",
						"notification_type": "chat",
					},
				},
			},
		},
	}
	message, err := client.Send(context.Background(), msg)
	if err != nil {
		log.Printf("Error sending message using FCM: %v\n", err)
	}
}

func getSEPSteps(sepID int, prompt string, retries int, debug bool) int {
	prompts := []openai.ChatCompletionMessage{
		{
			Role:    openai.ChatMessageRoleSystem,
			Content: prompt,
		},
	}
	sepChannel := make(chan string)
	go func(prompts []openai.ChatCompletionMessage, result chan<- string) {
		result <- openAIRequest(prompts)
	}(prompts, sepChannel)
	var message string
	message = <-sepChannel
	if len(message) > 0 {
		r, _ := regexp.Compile("([0-9]+,?[0-9]*)")

		tries := 0
		values := r.FindAllString(message, -1)
		for len(values) > 1 && tries < retries {
			prompts = append(prompts, openai.ChatCompletionMessage{
				Role:    openai.ChatMessageRoleAssistant,
				Content: message,
			}, openai.ChatCompletionMessage{
				Role:    openai.ChatMessageRoleSystem,
				Content: "isolate your answer to just provide the number",
			})
			tries = tries + 1
			if debug {
				fmt.Println("SEP "+strconv.Itoa(sepID)+" try: "+strconv.Itoa(tries), values)
			}
			go func(prompts []openai.ChatCompletionMessage, result chan<- string) {
				result <- openAIRequest(prompts)
			}(prompts, sepChannel)
			message = <-sepChannel
			if len(message) > 0 {
				values = r.FindAllString(message, -1)
				if debug {
					fmt.Println("SEP "+strconv.Itoa(sepID)+" try: "+strconv.Itoa(tries), values)
				}
				if len(values) > 1 {
					time.Sleep(100 * time.Millisecond)
				} else {
					break
				}
			}
		}
		if len(values) > 0 {
			steps, err := strconv.Atoi(strings.Replace(values[0], ",", "", -1))

			if err != nil {
				prompts = append(prompts, openai.ChatCompletionMessage{
					Role:    openai.ChatMessageRoleAssistant,
					Content: message,
				})
				if os.Getenv("DEBUG") == "true" {
					go logOutput(sepID, prompts)
				}
				panic(err)
			}
			prompts = append(prompts, openai.ChatCompletionMessage{
				Role:    openai.ChatMessageRoleAssistant,
				Content: message,
			})
			if os.Getenv("DEBUG") == "true" {
				go logOutput(sepID, prompts)
			}
			return steps
		}
	}
	prompts = append(prompts, openai.ChatCompletionMessage{
		Role:    openai.ChatMessageRoleAssistant,
		Content: message,
	})
	if os.Getenv("DEBUG") == "true" {
		go logOutput(sepID, prompts)
	}
	return -1
}

func executeQuery(db *sql.DB, query string, args ...any) []map[string]interface{} {
	rows, err := db.Query(query, args...)
	if err != nil {
		panic(err)
	}
	cols, _ := rows.Columns()
	nCols := len(cols)
	var results = make([]map[string]interface{}, 0)
	var rawResults = make([]interface{}, nCols)
	for i, _ := range rawResults {
		var ii interface{}
		rawResults[i] = &ii
	}
	for rows.Next() {
		rows.Scan(rawResults...)
		var entry = make(map[string]interface{})
		for i, colName := range cols {
			var rawValue = *(rawResults[i]).(*interface{})
			entry[colName] = rawValue
		}
		results = append(results, entry)
	}
	return results
}

func getUserToken(db *sql.DB, userID int) string {
	queryUserToken := executeQuery(db, "SELECT fcm_token FROM custom_auth_user "+
		"WHERE id = ?", strconv.Itoa(userID))
	if len(queryUserToken) > 0 {
		if queryUserToken[0]["fcm_token"] != nil {
			userTokenStr := ""
			userTokenStr = string(queryUserToken[0]["fcm_token"].([]uint8))
			return userTokenStr
		}
	}
	return ""
}

func sendSEPMessage(db *sql.DB, app *firebase.App, prompt string, conversation Conversation,
	userToken string) {
	message := generateProactiveMessage(0, prompt)
	firebaseConfig := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")
	app, err := setupFirebaseApp(firebaseConfig)
	if err != nil {
		log.Printf("Error could not start Firebase app: %v\n", err)
	} else {
		saveFBMessage(app, message, conversation.uuid)
		saveSEPMessage(db, conversation.sepId, conversation.id, message)
		fcmClient := setupFCMClient(app)
		sendFCMMessageToUser(message, userToken, fcmClient)
	}
}

func getSEPConversation(db *sql.DB, sepID int) *Conversation {
	querySEPConversationID := executeQuery(db, "SELECT * FROM custom_auth_conversation "+
		"WHERE simulated_peer_id = ?", strconv.Itoa(sepID))
	if len(querySEPConversationID) > 0 {
		if querySEPConversationID[0]["id"] != nil {
			/*conversationIDStr := ""
			conversationIDStr =
			convValueU64, _ := strconv.ParseUint(conversationIDStr, 10, 32)*/
			conversationID := int(querySEPConversationID[0]["id"].(int64))
			conversationUUID := string(querySEPConversationID[0]["uuid"].([]uint8))
			/*sepIDStr := string(querySEPConversationID[0]["simulated_peer_id"].([]uint8))
			sepValueU64, _ := strconv.ParseUint(sepIDStr, 10, 32)*/
			convSEPId := int(querySEPConversationID[0]["simulated_peer_id"].(int64))
			/*userIDStr := string(querySEPConversationID[0]["user_id"].([]uint8))
			valueU64, _ := strconv.ParseUint(userIDStr, 10, 32)*/
			userId := int(querySEPConversationID[0]["user1_id"].(int64))
			return &Conversation{
				id:     conversationID,
				uuid:   conversationUUID,
				sepId:  convSEPId,
				userId: userId,
			}
		}
	}
	return nil
}

func saveSEPSteps(db *sql.DB, sepID int, steps int, start time.Time, end time.Time) {
	_, err := db.Exec("INSERT INTO custom_auth_steprecord (count, start, end, sep_id) VALUES (?, ?, ?, ?)",
		steps, start.Format("2006-01-02 15:04:05"), end.Format("2006-01-02 15:04:05"), sepID)
	if err != nil {
		panic(err)
	}
}

func saveSEPMessage(db *sql.DB, sepID int, convID int, message string) {
	now := time.Now()
	_, err := db.Exec("INSERT INTO custom_auth_message (content, created_at, updated_at, "+
		"author_simulated_peer_id, author_user_id, conversation_id) VALUES (?, ?, ?, ?, NULL, ?)",
		message, now.Format("2006-01-02 15:04:05"), now.Format("2006-01-02 15:04:05"), strconv.Itoa(sepID),
		strconv.Itoa(convID))
	if err != nil {
		panic(err)
	}
}

func prepareSEPPrompt(db *sql.DB, sepID int, userID int) string {
	if err := db.Ping(); err != nil {
		db.Close()
		db = connectDatabase()
	}
	currentTime := time.Now()
	queryUserGoal := executeQuery(db, "SELECT * FROM custom_auth_goal WHERE user_id = ? AND start <= ? "+
		"AND end >= ?", strconv.Itoa(userID), currentTime.Format("2006-01-02 15:04:05"),
		currentTime.Format("2006-01-02 15:04:05"))
	userGoal := 70000
	startDateGoal := currentTime
	endDateGoal := currentTime
	if len(queryUserGoal) > 0 {
		userGoal = int(queryUserGoal[0]["value"].(int64))
		startDateGoal = queryUserGoal[0]["start"].(time.Time)
		endDateGoal = queryUserGoal[0]["end"].(time.Time)
	}
	lastHourTime := currentTime.Add(time.Duration(-1) * time.Hour)
	queryUserLastHourSteps := executeQuery(db, "SELECT SUM(count) as total_steps FROM custom_auth_steprecord "+
		"WHERE user_id = ? AND start >= ?", strconv.Itoa(userID), lastHourTime.Format("2006-01-02 15:04:05"))

	userLastHourSteps := uint32(0)
	if len(queryUserLastHourSteps) > 0 {
		if queryUserLastHourSteps[0]["total_steps"] != nil {
			userLastHourStepsStr := string(queryUserLastHourSteps[0]["total_steps"].([]uint8))
			valueU64, _ := strconv.ParseUint(userLastHourStepsStr, 10, 32)
			userLastHourSteps = uint32(valueU64)
		}
	}

	queryUserDoneSteps := executeQuery(db, "SELECT SUM(count) as total_steps FROM custom_auth_steprecord "+
		"WHERE user_id = ? AND start >= ?", strconv.Itoa(userID), startDateGoal.Format("2006-01-02 15:04:05"))
	currentWeekUserDoneSteps := uint32(0)
	if len(queryUserDoneSteps) > 0 {
		if queryUserDoneSteps[0]["total_steps"] != nil {
			currentWeekUserDoneStepsStr := ""
			currentWeekUserDoneStepsStr = string(queryUserDoneSteps[0]["total_steps"].([]uint8))
			valueU64, _ := strconv.ParseUint(currentWeekUserDoneStepsStr, 10, 32)
			currentWeekUserDoneSteps = uint32(valueU64)
		}
	}

	querySEPWeekSteps := executeQuery(db, "SELECT SUM(count) as total_steps FROM custom_auth_steprecord "+
		"WHERE sep_id = ? AND start >= ?", strconv.Itoa(sepID), startDateGoal.Format("2006-01-02 15:04:05"))

	sepWeekSteps := uint32(0)
	if len(querySEPWeekSteps) > 0 {
		if querySEPWeekSteps[0]["total_steps"] != nil {
			sepWeekStepsStr := string(querySEPWeekSteps[0]["total_steps"].([]uint8))
			valueU64, _ := strconv.ParseUint(sepWeekStepsStr, 10, 32)
			sepWeekSteps = uint32(valueU64)
		}
	}

	querySEPLastHourSteps := executeQuery(db, "SELECT SUM(count) as total_steps FROM custom_auth_steprecord "+
		"WHERE sep_id = ? AND start >= ?", strconv.Itoa(sepID), lastHourTime.Format("2006-01-02 15:04:05"))

	sepLastHourSteps := uint32(0)
	if len(querySEPLastHourSteps) > 0 {
		if querySEPLastHourSteps[0]["count"] != nil {
			sepLastHourStepsStr := string(querySEPLastHourSteps[0]["total_steps"].([]uint8))
			valueU64, _ := strconv.ParseUint(sepLastHourStepsStr, 10, 32)
			sepLastHourSteps = uint32(valueU64)
		}
	}

	diff := endDateGoal.Sub(currentTime)
	remainingDays := int(math.Round(diff.Hours() / 24))
	return fmt.Sprintf("You are the companion of a user that registers steps on a specific mobile application, "+
		"you are in a small competition with them and you need to respect the optimal challenge. You cannot register "+
		"more than 10000 steps during a day you need to consider that you walk every hour. I will give you data "+
		"about the user and you will have to suggest the number of steps that you will do in the next hour.\n   "+
		" - User steps in the past hour: %d\n    - User's and your week step goal: %d\n    - User steps done already: %d\n    "+
		"- Day remaining for goal completion: %d\n    - Steps you have done already: %d\n    "+
		"- Steps you have done in the past hour: %d\n    "+
		"Your response should only contain the number of steps you need to do in the next hour.", userLastHourSteps, userGoal,
		currentWeekUserDoneSteps, remainingDays, sepWeekSteps, sepLastHourSteps)
}

func sepActivityMotivation(db *sql.DB, sepID int, userID int) string {
	today := time.Now()
	// check for last message sent by sep in conversation
	queryLastSEPMessage := executeQuery(db, "SELECT * FROM custom_auth_message "+
		"WHERE author_simulated_peer_id = ? ORDER BY created_at DESC LIMIT 0, 1", strconv.Itoa(sepID))
	lastMessageDate := time.Date(1970, 01, 01, 00, 00, 00, 00, time.UTC)
	if len(queryLastSEPMessage) > 0 {
		if queryLastSEPMessage[0]["created_at"] != nil {
			lastMessageDate = queryLastSEPMessage[0]["created_at"].(time.Time)
			//valueU64, _ := strconv.ParseUint(sepLastMessageDateStr, 10, 32)
			//lastMessageDate, _ = time.Parse("2006-01-02 15:04:05", sepLastMessageDateStr)
		}
	}

	// check for user current day step count
	/*dayStartDate := time.Date(today.Year(), today.Month(), today.Day(), 0, 0, 0, 0,
		today.Location())
	queryUserCurrentDaySteps := executeQuery(db, "SELECT SUM(count) as total_steps FROM custom_auth_steprecord "+
		"WHERE user_id = ? AND start >= ?", strconv.Itoa(userID), dayStartDate.Format("2006-01-02 15:04:05"))
	currentDaySteps := uint32(0)
	if len(queryUserCurrentDaySteps) > 0 {
		if queryUserCurrentDaySteps[0]["total_steps"] != nil {
			currentDayStepsStr := string(queryUserCurrentDaySteps[0]["total_steps"].([]uint8))
			valueU64, _ := strconv.ParseUint(currentDayStepsStr, 10, 32)
			currentDaySteps = uint32(valueU64)
		}
	}*/

	// prompt agent for a message if it hasn't already sent a message today
	sendHourLimitGTE := time.Date(1970, 01, 01, 10, 00, 00, 00, time.Local)
	sendHourLimitLTE := time.Date(1970, 01, 01, 20, 00, 00, 00, time.Local)
	if today.Format("2006-01-02") != lastMessageDate.Format("2006-01-02") &&
		today.Hour() >= sendHourLimitGTE.Hour() && today.Hour() <= sendHourLimitLTE.Hour() {
		return fmt.Sprintf("Tu t'appelles Alex et tu es l'agent companion d'un utilisateur, " +
			"vous faites partie de l'expérience Excero qui vise à promouvoir l'activité physique." +
			"Tu ne lui as pas encore parlé aujourd'hui, écris un petit message qui pourrait l'inviter à lancer " +
			"la conversation avec toi aujourd'hui.")
	}
	return ""
}

func simulatedPeerWorker(db *sql.DB, sepID int, userID int, data chan SimulatedPeerStepRecord,
	messaging chan FirebaseMessagingRequest, wg *sync.WaitGroup) {
	if os.Getenv("DEBUG") == "true" {
		fmt.Println("SEP ", sepID, " is alive")
	}
	conversation := getSEPConversation(db, sepID)
	userToken := getUserToken(db, userID)
	sepProactivePrompt := sepActivityMotivation(db, sepID, conversation.id)
	if len(sepProactivePrompt) > 0 {
		messaging <- FirebaseMessagingRequest{conversation: conversation, prompt: sepProactivePrompt,
			userToken: userToken}
	}
	prompt := prepareSEPPrompt(db, sepID, userID)
	steps := getSEPSteps(sepID, prompt, 2, os.Getenv("DEBUG") == "true")
	cut := rand.Intn(30-1) + 1
	delay := 45 / cut
	stepsPerDelay := steps / cut
	stepsAcc := 0
	walkStartTime := time.Now()
	walkEndTime := time.Now()
	if stepsPerDelay > 0 {
		for stepsAcc < steps {
			if os.Getenv("DEBUG") == "true" {
				fmt.Println("SEP ", sepID, " is awake")
			}
			data <- SimulatedPeerStepRecord{sepID, stepsPerDelay, walkStartTime, walkEndTime}
			fmt.Println("SEP ", sepID, " inserted ", stepsPerDelay, " will sleep for", delay, "minutes")
			walkStartTime = walkEndTime
			sleepDuration := time.Duration(delay) * time.Minute
			walkEndTime = walkStartTime.Add(sleepDuration)
			stepsAcc = stepsAcc + stepsPerDelay
			time.Sleep(sleepDuration)
		}
	} else {
		data <- SimulatedPeerStepRecord{sepID, steps, walkStartTime, walkEndTime}
	}
	if os.Getenv("DEBUG") == "true" {
		fmt.Println("SEP ", sepID, " will die")
	}
	defer wg.Done()
}

func connectDatabase() *sql.DB {
	cfg := mysql.Config{
		User:                 os.Getenv("MYSQL_USERNAME"),
		Passwd:               os.Getenv("MYSQL_PASSWORD"),
		Net:                  "tcp",
		Addr:                 os.Getenv("MYSQL_HOST") + ":" + os.Getenv("MYSQL_PORT"),
		DBName:               os.Getenv("MYSQL_DATABASE"),
		ParseTime:            true,
		AllowNativePasswords: true,
	}
	db, err := sql.Open("mysql", cfg.FormatDSN())
	if err != nil {
		panic(err)
	}
	db.SetConnMaxLifetime(time.Hour * 1)
	return db
}

func getUsersInSEPCondition(db *sql.DB) []int {
	queryUsersInSEPCondition := executeQuery(db, "SELECT custom_auth_user.id as uid FROM custom_auth_user "+
		"INNER JOIN api_experimentalcondition "+
		"ON custom_auth_user.experimental_condition_id = api_experimentalcondition.id "+
		"WHERE api_experimentalcondition.acronym=\"SEP\"")
	var user_ids []int
	if len(queryUsersInSEPCondition) > 0 {
		for i := 0; i < len(queryUsersInSEPCondition); i++ {
			uid := queryUsersInSEPCondition[i]["uid"]
			if uid != nil {
				user_ids = append(user_ids, int(uid.(int64)))
			}
		}
	}
	return user_ids
}

func getSEPForUser(db *sql.DB, userID int) int {
	querySEPForUser := executeQuery(db, "SELECT simulated_peer_id as sid FROM custom_auth_user WHERE id = ?",
		strconv.Itoa(userID))
	if len(querySEPForUser) > 0 && querySEPForUser[0]["sid"] != nil {
		return int(querySEPForUser[0]["sid"].(int64))
	}
	return -1
}

func main() {
	var wg sync.WaitGroup
	fmt.Println("SEP shepherd is alive")
	sepsChan := make(chan SimulatedPeerStepRecord, 1)
	firebaseMessaging := make(chan FirebaseMessagingRequest, 1)
	if os.Getenv("DEBUG") == "true" {
		fmt.Println("SEP channel is created")
	}
	db := connectDatabase()
	writeDB := connectDatabase()
	writeMessageDB := connectDatabase()
	firebaseApp, _ := setupFirebaseApp("")
	fmt.Println("Connected")
	users := getUsersInSEPCondition(db)
	for _, uid := range users {
		wg.Add(1)
		sepID := getSEPForUser(db, uid)
		if sepID != -1 {
			go simulatedPeerWorker(db, sepID, uid, sepsChan, firebaseMessaging, &wg)
		}
	}

	go func() {
		wg.Wait()
		close(sepsChan)
		close(firebaseMessaging)
		db.Close()
		writeDB.Close()
		writeMessageDB.Close()
	}()
	for {
		select {
		case messageRequest := <-firebaseMessaging:
			if err := writeMessageDB.Ping(); err != nil {
				writeMessageDB.Close()
				writeMessageDB = connectDatabase()
			}
			sendSEPMessage(writeMessageDB, firebaseApp, messageRequest.prompt, *messageRequest.conversation,
				messageRequest.userToken)
			break
		case sepRecord := <-sepsChan:
			if os.Getenv("DEBUG") == "true" {
				fmt.Println("SEP ", sepRecord.id, " recorded ", sepRecord.steps, " steps.")
			}

			if err := writeDB.Ping(); err != nil {
				writeDB.Close()
				writeDB = connectDatabase()
			}
			saveSEPSteps(writeDB, sepRecord.id, sepRecord.steps, sepRecord.start, sepRecord.end)
			break
		}
	}
	fmt.Println("All SEPs are done, SEP shepherd will die...")
}
