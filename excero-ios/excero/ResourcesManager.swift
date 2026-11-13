//
//  ResourcesManager.swift
//  excero
//
//  Created by Alessandro on 29.09.23.
//

import Foundation
import SpriteKit
import RxSwift
import RxRelay
import XCGLogger
import BackgroundTasks
import CrashReporter

class ResourcesManager {
    static let instance = ResourcesManager()
    
    static let EVENT_INTERVENTIONWEEKS_SET: String = "ResourcesManager.EVENT_INTERVENTIONWEEKS_SET"
    static let EVENT_GOALS_SET: String = "ResourcesManager.EVENT_GOALS_SET"
    static let EVENT_WEEKSTEPS_SET: String = "ResourcesManager.EVENT_WEEKSTEPS_SET"
    static let EVENT_LOADRESOURCES: String = "ResourcesManager.LOAD_RESOURCES"
    static let DEFAULTS_SUITE_NAME: String = "group.ch.unil.silacci.excero"
    private static let USER_DEFAULT_IS_FIRST_LAUNCH: String = "ResourcesManager.USER_DEFAULT_IS_FIRST_LAUNCH"
        
    private var _user: UserRepresentation?
    private var _token: Token?
    private var _avatar: AvatarCodable?
    private var _networkAvailable: Bool = true
    private var _interventionWeeks: [InterventionWeekRepresentation]?
    private var _goals: [GoalRepresentation]?
    private var _userInfo: UserInformation?
    private var _analyticsController: AnalyticsController?
    
    private var _goalForWeek: [InterventionWeekRepresentation: GoalRepresentation]?
    
    private var _stepsPerWeek: [InterventionWeekRepresentation: Array<StepArchive>]?
    
    
    var user: UserRepresentation? {
        set {
            self._user = newValue
        }
        get {
            if let user = self._user {
                return user
            } else {
                let userModelController = ModelController<User>()
                if let userCD = userModelController.getLast() {
                    Task {
                        do {
                            self._user = try await UserRepresentation.fromCDUser(user: userCD)
                            return self._user
                        } catch {
                            return nil
                        }
                    }
                }
            }
            return nil
        }
    }

    
    var token: Token? {
        set {
            self._token = newValue
        }
        get {
            return self._token
        }
    }
    
    var userInfo: UserInformation? {
        set {
            self._userInfo = newValue
        }
        get {
            return self._userInfo
        }
    }
    
    var avatar: AvatarCodable? {
        set {
            self._avatar = newValue
        }
        get {
            return self._avatar
        }
    }
    
    var networkAvailable: Bool {
        set {
            self._networkAvailable = newValue
        }
        get {
            return self._networkAvailable
        }
    }
    
    var interventionWeeks: [InterventionWeekRepresentation]? {
        set {
            self._interventionWeeks = newValue
            EventDispatcher.instance.emit(EventDispatcher.DispatchableEvent(identifier: ResourcesManager.EVENT_INTERVENTIONWEEKS_SET))
        }
        get {
            return self._interventionWeeks
        }
    }
    
    var goals: [GoalRepresentation]? {
        set {
            if self._goals == nil {
                EventDispatcher.instance.emit(EventDispatcher.DispatchableEvent(identifier: ResourcesManager.EVENT_GOALS_SET))
            }
            self._goals = newValue
        }
        get {
            return self._goals
        }
    }
    
    var stepsPerWeek: [InterventionWeekRepresentation: Array<StepArchive>]? {
        get {
            return self._stepsPerWeek
        }
    }
    
    var goalForWeek: [InterventionWeekRepresentation: GoalRepresentation]? {
        get {
            return self._goalForWeek
        }
    }
    
    var stepOfDayStream: BehaviorRelay<StepRecordRepresentation> = BehaviorRelay<StepRecordRepresentation>(value: StepRecordRepresentation(url: nil, value: 0, start: Date(), end: Date()))
    
    var peerStepsOfDayStream: BehaviorRelay<StepRecordRepresentation> = BehaviorRelay<StepRecordRepresentation>(value: StepRecordRepresentation(url: nil, value: 0, start: Date(), end: Date()))
    
    var openingURL: BehaviorRelay<URL?> = BehaviorRelay<URL?>(value: nil)
    
    let cache: NSCache<NSString, AnyObject> = NSCache()
    
    var logDocumentPath: String {
        get {
            do {
                var documentPath = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                return documentPath.appendingPathComponent("excero_app_log.txt").absoluteString
            } catch {
                return "excero_app_log.txt"
            }
        }
    }
    
    static let logger: XCGLogger = {
        let log = XCGLogger(identifier: "ch.unil.silacci.excero.LOGGER", includeDefaultDestinations: false)
        let systemDestination = AppleSystemLogDestination(identifier: "advancedLogger.systemDestination")

        systemDestination.outputLevel = .debug
        systemDestination.showLogIdentifier = false
        systemDestination.showFunctionName = true
        systemDestination.showThreadName = true
        systemDestination.showLevel = true
        systemDestination.showFileName = true
        systemDestination.showLineNumber = true
        systemDestination.showDate = true

        log.add(destination: systemDestination)
        
        do {
            var documentPath = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileDestination = FileDestination(writeToFile: documentPath.appendingPathComponent("excero_app_log.txt").absoluteString, identifier: "ch.unil.silacci.excero.LOGGER")
            
            fileDestination.outputLevel = .debug
            fileDestination.showLogIdentifier = false
            fileDestination.showFunctionName = true
            fileDestination.showThreadName = true
            fileDestination.showLevel = true
            fileDestination.showFileName = true
            fileDestination.showLineNumber = true
            fileDestination.showDate = true

            fileDestination.logQueue = XCGLogger.logQueue

            log.add(destination: fileDestination)
        } catch {
            
        }

        log.logAppDetails()
        return log
    }()
    
    var crashReporter: PLCrashReporter? {
        get {
            if !ResourcesManager.isDebuggerAttached() {
                let config = PLCrashReporterConfig(signalHandlerType: .mach, symbolicationStrategy: [])
                return PLCrashReporter(configuration: config)
            }
            return nil
        }
    }
    
    internal init() {
        EventDispatcher.instance.subscribe() { event in
            switch event.identifier {
            case ResourcesManager.EVENT_LOADRESOURCES:
                if ResourcesManager.instance.networkAvailable {
                    Task {
                        await self.loadUserData()
                    }
                }
            case ResourcesManager.EVENT_INTERVENTIONWEEKS_SET:
                if self._stepsPerWeek == nil {
                    self._stepsPerWeek = [:]
                }
                if self._goalForWeek == nil {
                    self._goalForWeek = [:]
                }
            case AppOrchestrator.ORCHESTRATOR_EVENT_LOAD_STORYBOARD:
                if let content = event.content as? AppOrchestrator.StoryBoardBundle {
                    print("Loading view: \(content.viewName) in storyboard: \(content.storyboardName)")
                }
            default:
                print("Event emitted: \(event.identifier)")
            }
        }
        
    }
    
    public var isFirstLaunch: Bool {
        get {
            let defaults = UserDefaults.standard
            if let _ = defaults.object(forKey: ResourcesManager.USER_DEFAULT_IS_FIRST_LAUNCH) {
                return defaults.bool(forKey: ResourcesManager.USER_DEFAULT_IS_FIRST_LAUNCH)
            } else {
                return true
            }
        }
        set {
            let defaults = UserDefaults.standard
            defaults.set(newValue, forKey: ResourcesManager.USER_DEFAULT_IS_FIRST_LAUNCH)
        }
    }
    
    static func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib : [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout.stride(ofValue: info)
        let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        assert(junk == 0, "sysctl failed")
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    public func registerUserEvent(action: ActionNames, target: String) {
        guard let user = self._user else {
            return
        }
        if self._analyticsController == nil {
            self._analyticsController = AnalyticsController(user: user)
        }
        Task {
            await self._analyticsController?.storeAnalyticEvent(action: action, target: target)
        }
    }
    
    public func saveResources() {
        do {
            let _ = self._user?.toCodable()
            try CoreDataController.instance.mainContext.save()
        } catch {
            print("Error while saving data")
        }
    }
    
    private func downloadResource<T: Codable>(url: String) async throws -> T? {
        let apiAuth = AuthenticatedApiFacade()
        let data = try await apiAuth.get(fullUrl: url.replacingOccurrences(of: "http", with: "https"), header: nil)
        if let data = data {
            let decoder = JSONDecoder()
            let resource = try decoder.decode(T.self, from: data)
            return resource
        }
        return nil
    }
    
    public func loadSKAvatar(avatarModel: Avatar, parentScene: SKScene) async throws -> SKAvatar? {
        let representation = try await AvatarRepresentation.fromCDAvatar(avatarModel)
        return try await representation?.toSKAvatar(parentScene: parentScene)
    }
    
    public func loadUserData() async {
        let apiAuth = AuthenticatedApiFacade()
        let changeViewEvent = EventDispatcher.DispatchableEvent(identifier: SceneDelegate.SCENEDELEGATE_CHANGEVIEW_EVENT)
        do {
            let userSelfData = try await apiAuth.get(endpointPath: "users/self/", header: nil)
            if let userSelfData = userSelfData {
                let decoder = JSONDecoder()
                let userSelf = try decoder.decode([UserCodable].self, from: userSelfData)
                ResourcesManager.instance.user = try await UserRepresentation.fromCodable(user: userSelf[0])
            }
        } catch {
            changeViewEvent.content = SceneDelegate.SceneDelegateChangeViewEvent(storyBoardName: "Authentication", viewName: "Authentication") as AnyObject
        }
        
        if changeViewEvent.content != nil {
            EventDispatcher.instance.emit(changeViewEvent)
        }
    }
    
    public func loadInterventionWeeks() {
        Task {
            let apiAuth = AuthenticatedApiFacade()
            let iwModelController = ModelController<InterventionWeek>()
            if ResourcesManager.instance.networkAvailable {
                do {
                    let interventionsData = try await apiAuth.get(endpointPath: "interventions/", header: nil)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    if let iwData = interventionsData {
                        let iwCodables = try decoder.decode([InterventionWeekCodable].self, from: iwData)
                        var iws: [InterventionWeekRepresentation] = []
                        for iw in iwCodables {
                            if let iwDB = InterventionWeekRepresentation.fromCodable(interventionWeek: iw) {
                                iws.append(iwDB)
                            }
                        }
                        ResourcesManager.instance.interventionWeeks = iws
                        print("Data initialized")
                    }
                    //ResourcesManager.instance.saveResources()
                    
                } catch AuthenticatedApiCallError.invalidRefreshToken(token: let _) {
                    //self.loadViewWithName(storyboardName: "Authentication", viewName: "Authentication")
                    print("Received invalid refresh token on intervention weeks")
                } catch {
                    print("error initializedata \(error)")
                }
            } else {
                let cdiws = iwModelController.list()
                var iws: [InterventionWeekRepresentation] = []
                for cdiw in cdiws {
                    if let iw = InterventionWeekRepresentation.fromCD(element: cdiw) {
                        iws.append(iw)
                    }
                }
                ResourcesManager.instance.interventionWeeks = iws
            }
        }
    }
    
    public func loadHKStepsForWeek(interventionWeek: InterventionWeekRepresentation, callback: @escaping ([StepRecordRepresentation]) -> Void) {
        Task {
            let days = Calendar.current.dateComponents([.day], from: interventionWeek.begin!, to: interventionWeek.end!)
            var spw: [StepRecordRepresentation] = []
            var daysCounter = 0
            for day in 0...days.day! {
                let requestDay = Calendar.current.date(byAdding: .day, value: day, to: interventionWeek.begin!)
                let startRequestDay = Calendar.current.startOfDay(for: requestDay!).localDate()
                var comp = DateComponents()
                comp.day = 1
                comp.second = -1
                let endRequestDay = Calendar.current.date(byAdding: comp, to: startRequestDay)
                do {
                    let result = try await HealthKitUtility.instance.getStepsRecordInPeriod(from: startRequestDay, to: endRequestDay!)
                    /*await CoreDataController.instance.mainContext.perform {
                        let step = StepArchive(context: CoreDataController.instance.mainContext)
                        step.start = result?.0
                        step.end = result?.0
                        step.value = Int32(result?.1 ?? 0)
                        spw.append(step)
                        
                        do {
                            try CoreDataController.instance.mainContext.save()
                        } catch {
                            ResourcesManager.logger.error("ResourcesManager.loadHKStepsForWeek could not save coredata context. Detailed error: \(error)")
                        }
                    }*/
                    spw.append(StepRecordRepresentation(url: "", value: Int32(result?.1 ?? 0), start: result?.0 ?? Date(), end: result?.0 ?? Date()))
                    
                    daysCounter += 1
                } catch {
                    fatalError("Count not retrieve steps \(error.localizedDescription)")
                }
            }
            callback(spw)
        }
    }
    
    public func getHKSteps(from: Date, to: Date = Date(), interval: DateComponents = DateComponents(day: 1)) -> Observable<[StepRecordRepresentation]> {
        return Observable.create { observer in
            Task {
                do {
                    if let results = try await HealthKitUtility.instance.executeStatisticsQuery(from: from, to: to, interval: interval) {
                        var steps: [StepRecordRepresentation] = []
                        for result in results {
                            if let qty = result.sumQuantity() {
                                let sumSteps = qty.doubleValue(for: .count())
                                let stepRecord = StepRecordRepresentation(url: "", value: Int32(sumSteps), start: result.startDate, end: result.endDate)
                                steps.append(stepRecord)
                            }
                        }
                        observer.on(.next(steps))
                        observer.on(.completed)
                    }
                } catch {
                    observer.on(.error(RxError.noElements))
                    observer.on(.completed)
                }
            }
            return Disposables.create()
        }
    }
    
    public func loadWeekGoals(user: UserRepresentation) {
        Task {
            if let goals = await self.loadUserGoals(user: user) {
                for week in self._interventionWeeks! {
                    for goal in goals {
                        if goal.start! >= week.begin! && goal.end! <= week.end! {
                            self._goalForWeek![week] = goal
                            break
                        }
                    }
                }
                EventDispatcher.instance.emit(EventDispatcher.DispatchableEvent(identifier: ResourcesManager.EVENT_GOALS_SET))
            }
        }
    }
    
    public func getWeekSteps(week: InterventionWeekRepresentation) -> Observable<Array<StepRecordRepresentation>> {
        return Observable.create { observer in
            self.loadHKStepsForWeek(interventionWeek: week) { stepsForWeek in
                observer.on(.next(stepsForWeek))
                observer.on(.completed)
            }
            return Disposables.create()
        }
    }
    
    public func getUserWeeklyGoals(user: UserRepresentation) -> Observable<[InterventionWeekRepresentation:GoalRepresentation]> {
        return Observable.create { observer in
            if let weeklyGoals = self._goalForWeek, weeklyGoals.count > 0 {
                observer.on(.next(weeklyGoals))
                observer.on(.completed)
            } else {
                Task {
                    var interventionWeeks: [InterventionWeekRepresentation] = []
                    if self._interventionWeeks == nil {
                        for try await iws in self.getInterventionWeeks().values {
                            interventionWeeks = iws
                            self._interventionWeeks = iws
                        }
                    }
                    if let goals = await self.loadUserGoals(user: user) {
                        for week in interventionWeeks {
                            for goal in goals {
                                if goal.start! >= week.begin! && goal.end! <= week.end! {
                                    self._goalForWeek![week] = goal
                                    break
                                }
                            }
                        }
                        observer.on(.next(self._goalForWeek!))
                        observer.on(.completed)
                    }
                }
            }
            return Disposables.create()
        }
        
    }
    
    public func getUserInfo() -> Maybe<UserInformation> {
        return Maybe<UserInformation>.create { observer in
            let userInfoController = ModelController<UserInformation>()
            if let userInfo = self._userInfo {
                observer(.success(userInfo))
                observer(.completed)
            } else if let infos = userInfoController.getLast() {
                    self._userInfo = infos
                    observer(.success(infos))
                    observer(.completed)
            } else {
                observer(.error(RxError.noElements))
            }
            return Disposables.create()
        }
    }
    
    public func getCurrentUser() -> Maybe<UserRepresentation> {
        return Maybe<UserRepresentation>.create { observer in
            if let user = ResourcesManager.instance.user {
                observer(.success(user))
                observer(.completed)
            } else {
                if self._networkAvailable {
                    Task {
                        await self.loadUserData()
                        if let user = self._user {
                            observer(.success(user))
                            observer(.completed)
                        }
                    }
                } else {
                    let userModelController = ModelController<User>()
                    if let userCD = userModelController.getLast() {
                        Task {
                            do {
                                if let user = try await UserRepresentation.fromCDUser(user: userCD) {
                                    self._user = user
                                    observer(.success(user))
                                    observer(.completed)
                                }
                            } catch {
                                observer(.error(error))
                            }
                        }
                    } else {
                        observer(.error(RxError.noElements))
                    }
                }
            }
            return Disposables.create()
        }
    }
    
    public func clearNotifications(withResourceType: String? = nil, removeBadges: Bool = false, storedCountName: String? = nil) -> Void {
        let center = UNUserNotificationCenter.current()
        var notificationsToRemove: [String] = []
        center.getDeliveredNotifications() { notifications in
            var currentBadgeCount: Int?
            if(removeBadges) {
                if let storedCountName = storedCountName {
                    currentBadgeCount = UserDefaults(suiteName: Constants.USER_DEFAULTS_SUITE_NAME)?.object(forKey: storedCountName) as? Int ?? 0
                }
            }
            var totalBadgeCount: Int = currentBadgeCount ?? 0
            for notification in notifications {
                let userInfo = notification.request.content.userInfo
                totalBadgeCount += notification.request.content.badge as! Int? ?? 0 
                if let resourceType = withResourceType {
                    if(userInfo["notification_type"] as! String == resourceType) {
                        totalBadgeCount = totalBadgeCount - 1
                        notificationsToRemove.append(notification.request.identifier)
                    }
                } else {
                    if(userInfo["notification_type"] == nil) {
                        totalBadgeCount = totalBadgeCount - 1
                        notificationsToRemove.append(notification.request.identifier)
                    }
                }
            }
            Task { [totalBadgeCount] in
                if #available(iOS 16.0, *) {
                    if(removeBadges) {
                        try await center.setBadgeCount(totalBadgeCount)
                        if let storedCountName = storedCountName {
                            UserDefaults.standard.setValue(totalBadgeCount, forKey: storedCountName)
                        }
                    }
                } else {
                    // Fallback on earlier versions
                }
            }
        }
        center.removeDeliveredNotifications(withIdentifiers: notificationsToRemove)
    }
    
    public func getInterventionWeeks() -> Observable<[InterventionWeekRepresentation]> {
        return Observable.create { observer in
            
            if let iws = self._interventionWeeks {
                observer.on(.next(iws))
                observer.on(.completed)
            } else {
                Task {
                    let apiAuth = AuthenticatedApiFacade()
                    let iwModelController = ModelController<InterventionWeek>()
                    if ResourcesManager.instance.networkAvailable {
                        do {
                            let interventionsData = try await apiAuth.get(endpointPath: "interventions/", header: nil)
                            let decoder = JSONDecoder()
                            decoder.dateDecodingStrategy = .iso8601
                            if let iwData = interventionsData {
                                let iwCodables = try decoder.decode([InterventionWeekCodable].self, from: iwData)
                                var iws: [InterventionWeekRepresentation] = []
                                for iw in iwCodables {
                                    if let iwr = InterventionWeekRepresentation.fromCodable(interventionWeek: iw) {
                                        iws.append(iwr)
                                        let _ = iwr.toCD()
                                    }
                                }
                                //ResourcesManager.instance.saveResources()
                                
                                ResourcesManager.instance.interventionWeeks = iws
                                observer.on(.next(iws))
                                observer.on(.completed)
                                print("Data initialized")
                            }
                        } catch AuthenticatedApiCallError.invalidRefreshToken(token: _) {
                            //self.loadViewWithName(storyboardName: "Authentication", viewName: "Authentication")
                            print("Received invalid refresh token on intervention weeks")
                        } catch {
                            print("error initializedata \(error)")
                        }
                    } else {
                        let iwCDs = iwModelController.list()
                        var iws: [InterventionWeekRepresentation] = []
                        for iwCD in iwCDs {
                            if let iwr = InterventionWeekRepresentation.fromCD(element: iwCD) {
                                iws.append(iwr)
                            }
                        }
                        ResourcesManager.instance.interventionWeeks = iws
                        observer.on(.next(iws))
                        observer.on(.completed)
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    /*public func scheduleAppBGTask() {
        guard let user = self._user else { return }
        let task = BGAppRefreshTaskRequest(identifier: Constants.URLSESSION_BG_IDENTIFIER)
        task.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(task)
        } catch {
            ResourcesManager.logger.error("ResourcesManager.scheduleAppBGTask could not schedule background task. Detailed error: \(error)")
        }
    }*/
    
    private func loadUserInformation() -> UserInformation? {
        let userInfoModelController = ModelController<UserInformation>()
        return userInfoModelController.getLast()
    }
    
    
    private func loadUserGoals(user: UserRepresentation) async -> [GoalRepresentation]? {
        let apiAuth = AuthenticatedApiFacade()
        // guard let user = ResourcesManager.instance.user else { return nil } // FIXME: User is null when at this point.
        do {
            let goalsData = try await apiAuth.get(fullUrl: user.url!.replacingOccurrences(of: "http", with: "https") + "goals/", header: nil)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let goalsData = goalsData {
                let goalCodables = try decoder.decode([GoalCodable].self, from: goalsData)
                var goals: [GoalRepresentation] = []
                for goalCodable in goalCodables {
                    if let goal = GoalRepresentation.fromCodable(goal: goalCodable) {
                        goals.append(goal)
                    }
                }
                return goals
            }
        } catch {
            print("Error when retrieving goals: \(error.localizedDescription)")
        }
        return nil
    }
}
