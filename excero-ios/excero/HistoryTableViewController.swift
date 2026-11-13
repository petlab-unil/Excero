//
//  HistoryTableViewController.swift
//  excero
//
//  Created by Alessandro Silacci on 05.09.22.
//

import Foundation
import UIKit

class HistoryTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var goalController: GoalController?
    
    private static let DEFAULT_GOAL: Int = 10000
    
    class CustomHistoryHeader: UITableViewHeaderFooterView {
        let title: UILabel = UILabel()
        let trophyHolder: UIImageView = UIImageView()
        
        override init(reuseIdentifier: String?) {
            super.init(reuseIdentifier: reuseIdentifier)
            self.configHeader()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            self.configHeader()
        }
               
        func configHeader() {
            self.trophyHolder.translatesAutoresizingMaskIntoConstraints = false
            self.title.translatesAutoresizingMaskIntoConstraints = false
            
            self.contentView.addSubview(self.trophyHolder)
            self.contentView.addSubview(self.title)
            
            
            NSLayoutConstraint.activate([
                self.trophyHolder.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor, constant: 10),
                self.trophyHolder.widthAnchor.constraint(equalToConstant: 30),
                self.trophyHolder.heightAnchor.constraint(equalToConstant: 30),
                self.trophyHolder.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
                
                self.title.heightAnchor.constraint(equalToConstant: 30),
                self.title.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor, constant: 8),
                self.title.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor),
                self.title.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor)
                
            ])
        }
    }
    
    class CustomHistoryCell: UITableViewCell {
        let day: UILabel = UILabel()
        let steps: UILabel = UILabel()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            self.configCell()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            self.configCell()
        }
        
        
        func configCell() {
            self.day.translatesAutoresizingMaskIntoConstraints = false
            self.steps.translatesAutoresizingMaskIntoConstraints = false
            
            self.steps.textAlignment = .right
            
            self.contentView.addSubview(self.day)
            self.contentView.addSubview(self.steps)
            
            
            NSLayoutConstraint.activate([
                self.steps.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor, constant: 10),
                self.steps.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
                
                self.day.heightAnchor.constraint(equalToConstant: 30),
                self.day.leadingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.leadingAnchor, constant: 8),
                self.day.trailingAnchor.constraint(equalTo: self.contentView.layoutMarginsGuide.trailingAnchor),
                self.day.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor)
                
            ])
        }
    
    }
    
    private var stepRecords: Array<StepArchive> = []
    
    private var numberOfWeeks: Int = 2
    private let numberOfDayInWeek: Int = 7
    
    private var interventionWeeks: [InterventionWeekRepresentation]?
    
    private var weekSteps: [InterventionWeekRepresentation: Array<StepRecordRepresentation>] = [:]
    
    private var weekGoals: [InterventionWeekRepresentation: GoalRepresentation] = [:]
    
    private var loadingActivityView: UIActivityIndicatorView?
    
    @IBOutlet weak var historyTableView: UITableView!
    
    private let dateFormatter: DateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadingActivityView = UIActivityIndicatorView(style: .large)
        self.loadingActivityView!.startAnimating()
        self.historyTableView.backgroundView = self.loadingActivityView!
        
        Task {
            do {
                if let user = try await ResourcesManager.instance.getCurrentUser().value {
                    self.goalController = GoalController(user: user)
                }
            } catch {
                // -- MARK: move back to authentication page.
                ResourcesManager.logger.error("HistoryView.viewDidLoad could not load user from ResourceManager. Detailed error: \(error)")
            }
            let iwController = InterventionWeekController()
            let interventionweeks = await iwController.listInterventionWeeks()
            if let interventionweeks {
                self.interventionWeeks = interventionweeks
                for week in interventionweeks {
                    #if targetEnvironment(simulator)
                    if let beginDate = week.begin, let endDate = week.end {
                        let start = Calendar.current.startOfDay(for: beginDate)
                        let end = Calendar.current.startOfDay(for: endDate)
                        var steps: [StepRecordRepresentation] = []
                        if let nbDaysInWeek = Calendar.current.dateComponents([.day], from: start, to: end).day {
                            for i in 0...nbDaysInWeek {
                                let randomSteps = Int.random(in: 1...70000)
                                if let startDayRandomSteps = Calendar.current.date(byAdding: DateComponents(day: i), to: start),
                                   let endDayRandomSteps = Calendar.current.date(byAdding: DateComponents(hour: 23, minute: 59, second: 59), to: startDayRandomSteps) {
                                    steps.append(StepRecordRepresentation(url: nil, value: Int32(randomSteps), start: startDayRandomSteps, end: endDayRandomSteps))
                                }
                            }
                        }
                        if self.weekSteps.contains(where: {$0.key == week }) {
                            self.weekSteps.updateValue(steps, forKey: week)
                        } else {
                            self.weekSteps[week] = steps
                        }
                    }
                    #else
                    do {
                        for try await steps in ResourcesManager.instance.getWeekSteps(week: week).values {
                            if self.weekSteps.contains(where: {$0.key == week }) {
                                self.weekSteps.updateValue(steps, forKey: week)
                            } else {
                                self.weekSteps[week] = steps
                            }
                        }
                    } catch {
                        ResourcesManager.logger.error("HistoryView.viewDidLoad could not load steps for week \(week). Detailed error: \(error)")
                    }
                    #endif
                    do {
                        self.weekGoals[week] = try await self.goalController?.getGoalForWeek(week)
                    } catch {
                        
                    }
                }
                DispatchQueue.main.async {
                    self.historyTableView.backgroundView = nil
                    self.historyTableView.delegate = self
                    self.historyTableView.dataSource = self
                    self.historyTableView.register(CustomHistoryHeader.self, forHeaderFooterViewReuseIdentifier: "history-header")
                    self.historyTableView.register(CustomHistoryCell.self, forCellReuseIdentifier: "history-cell")
                    self.historyTableView.reloadData()
                }
            }
        }
        
        self.dateFormatter.dateFormat = "EEEE"
        
        self.historyTableView.sectionHeaderHeight = 60
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ResourcesManager.instance.registerUserEvent(action: .VIEW_CHANGE, target: self.getViewControllerName())
        self.loadingActivityView = UIActivityIndicatorView(style: .large)
        self.loadingActivityView!.startAnimating()
        self.historyTableView.backgroundView = self.loadingActivityView!
        
        Task {
            do {
                if let user = try await ResourcesManager.instance.getCurrentUser().value {
                    self.goalController = GoalController(user: user)
                }
            } catch {
                ResourcesManager.logger.error("HistoryTableViewController.viewDidAppear could not load user from ResourceManager. Detailed error: \(error)")
            }
            var weeklyGoals: [InterventionWeekRepresentation: GoalRepresentation] = [:]
            var weeklySteps: [InterventionWeekRepresentation: Array<StepRecordRepresentation>] = [:]
            let iwController = InterventionWeekController()
            let interventionweeks = await iwController.listInterventionWeeksUntilDate(Date())
            if let interventionweeks {
                for week in interventionweeks {
                    #if targetEnvironment(simulator)
                    if let beginDate = week.begin, let endDate = week.end {
                        let start = Calendar.current.startOfDay(for: beginDate)
                        let end = Calendar.current.startOfDay(for: endDate)
                        var steps: [StepRecordRepresentation] = []
                        if let nbDaysInWeek = Calendar.current.dateComponents([.day], from: start, to: end).day {
                            for i in 0...nbDaysInWeek {
                                let randomSteps = Int.random(in: 1...70000)
                                if let startDayRandomSteps = Calendar.current.date(byAdding: DateComponents(day: i), to: start),
                                   let endDayRandomSteps = Calendar.current.date(byAdding: DateComponents(hour: 23, minute: 59, second: 59), to: startDayRandomSteps) {
                                    steps.append(StepRecordRepresentation(url: nil, value: Int32(randomSteps), start: startDayRandomSteps, end: endDayRandomSteps))
                                }
                            }
                        }
                        if weeklySteps.contains(where: {$0.key == week }) {
                            weeklySteps.updateValue(steps, forKey: week)
                        } else {
                            weeklySteps[week] = steps
                        }
                    }
                    #else
                    do {
                        for try await steps in ResourcesManager.instance.getWeekSteps(week: week).values {
                            if weeklySteps.contains(where: {$0.key == week }) {
                                weeklySteps.updateValue(steps, forKey: week)
                            } else {
                                weeklySteps[week] = steps
                            }
                        }
                    } catch {
                        ResourcesManager.logger.error("HistoryTableViewController.viewDidAppear could not load steps for week \(week). Detailed error: \(error)")
                    }
                    #endif
                    do {
                        if let goal = try await self.goalController?.getGoalForWeek(week) {
                            if weeklyGoals.contains(where: {$0.key == week }) {
                                weeklyGoals.updateValue(goal, forKey: week)
                            } else {
                                weeklyGoals[week] = goal
                            }
                        }
                    } catch {
                        ResourcesManager.logger.error("HistoryTableViewController.viewDidAppear could not load user from ResourceManager. Detailed error: \(error)")
                    }
                }
                
                self.interventionWeeks = interventionweeks
                self.weekGoals = weeklyGoals
                self.weekSteps = weeklySteps
                DispatchQueue.main.async {
                    self.historyTableView.backgroundView = nil
                    self.historyTableView.delegate = self
                    self.historyTableView.dataSource = self
                    self.historyTableView.reloadData()
                }
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.interventionWeeks?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let interventionWeeks = self.interventionWeeks, section < interventionWeeks.count {
            let iw = interventionWeeks[section]
            if let res = self.weekSteps[iw] {
                return res.count
            }
        }
        return self.numberOfDayInWeek
    }
    
    func getRecordForDateRange(begin: Date, end: Date) -> StepArchive? {
        for record in self.stepRecords {
            guard let startDate = record.start else { continue }
            guard let endDate = record.end else { continue }
            if startDate >= begin && endDate <= end {
                return record
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let iwL = self.interventionWeeks?.count ?? 0
        var interventionWeek: InterventionWeekRepresentation?
        if let iws = self.interventionWeeks, indexPath.section < iws.count {
            interventionWeek = iws[indexPath.section]
        }
        
        if let cell = self.historyTableView.dequeueReusableCell(withIdentifier: "history-cell") as! CustomHistoryCell? {
            if let iw = interventionWeek, let currentCells = self.weekSteps[iw] {
                if currentCells.count <= indexPath.row {
                    ResourcesManager.logger.warning("HistoryTableViewController generation of cellsForRowAt potential error can trigger, index is out of bound \(indexPath.row) /\(currentCells.count).")
                }
                let currentCell = currentCells[indexPath.row]
                cell.day.text = self.dateFormatter.string(from: currentCell.start!)
                cell.steps.text = String(currentCell.value)
            }
            return cell
        } else {
            let cell = CustomHistoryCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "history-cell")
            if let iw = interventionWeek, let currentCells = self.weekSteps[iw] {
                let currentCell = currentCells[indexPath.row]
                cell.day.text = self.dateFormatter.string(from: currentCell.start!)
                cell.steps.text = String(currentCell.value)
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let view = self.historyTableView.dequeueReusableHeaderFooterView(withIdentifier: "history-header") as? CustomHistoryHeader else {
            ResourcesManager.logger.error("HistoryTableViewController.tableView Could not dequeue header view.")
            return nil
        }
        
        let iconCompletion = UIImage(named: "ui_trophy")
        let iconNormal = UIImage(named: "ui_trophy_outline")
        
        let interventionWeek = self.interventionWeeks?[section]
        var goal = Constants.DEFAULT_STEP_GOAL
        var cumulatedSteps = 0
        if let iw = interventionWeek, let stepsPerWeek = self.weekSteps[iw] {
            for record in stepsPerWeek {
                cumulatedSteps += Int(record.value)
            }
        }
        
        if let iw = interventionWeek, let goalForWeek = self.weekGoals[iw] {
            goal = Int(goalForWeek.value ?? -1)
        }
        
        view.title.text = "Semaine \(section) - \(goal)"
        
        if cumulatedSteps >= goal {
            view.trophyHolder.image = iconCompletion
        } else {
            view.trophyHolder.image = iconNormal
        }
        
        return view
    }
    
}
