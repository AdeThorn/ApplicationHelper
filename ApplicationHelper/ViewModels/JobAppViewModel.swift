//
//  JobAppViewModel.swift
//  ApplicationHelper
//
//  Created by Ade Thornhill on 8/22/21.
//

import SwiftUI
import CoreData
class JobAppViewModel : ObservableObject {
    
    @Published var applications: [JobApplication] = [] //all created job applications
    let filters : [Command] = [NoneCommand(),FavouriteFilter(),AppliedFilter(),InterviewFilter(),AcceptedFilter(),RejectedFilter()] // filters used to filter applications
    
    let descriptors : [Command] = [ AscendDate(), DescendDate() ]
    
    let container: NSPersistentContainer
    
    init(){
        container = NSPersistentContainer(name: "JopApplicationContainer")
        //load data from container
        container.loadPersistentStores{
            (description,error) in
            if let error = error {
                print("Error loading Core Data: \(error)")
            }
        }
        
        fetchApplications()
    }
    
    //get data from core data database
    func fetchApplications(){
        let request = NSFetchRequest<JobApplication>(entityName:"JobApplication")
        
        do{
            applications =  try container.viewContext.fetch(request)
        } catch let error{
            print("Error when fetching : \(error)")
        }
        
    }
    
    //function for adding new applications
    func addApplication(companyName:String, jobTitle:String , dateApplied:Date){
        let newApp = JobApplication(context: container.viewContext)
        newApp.company = companyName
        newApp.title = jobTitle
        newApp.dateApplied = dateApplied
        newApp.status = "Applied"
        newApp.isFavourite = false
        saveData()
    }
    
    func deleteApplication(jobApp : JobApplication){
        //Remove scheduled notifications for this app
        NotificationManager.getInstance().removeAppNoti(jobApp: jobApp)
        if applications.contains(jobApp){
            container.viewContext.delete(jobApp)
            saveData()
        }
    }
    
    //function to favourite or unfavourite an application
    func toggleFavourite(jobApp:JobApplication){
        jobApp.isFavourite = !jobApp.isFavourite
        saveData()
    }
    
    func updateStatus(jobApp:JobApplication, status:String , importantDate: Date = Date(timeIntervalSince1970: 0) ){
        jobApp.status = status
        if status.contains("Interview"){
            jobApp.importantDate = importantDate
            
            if importantDate == Date(timeIntervalSince1970: 0) {
                jobApp.importantDate = Date()
            }
        }
        else{
            jobApp.importantDate = nil
        }
        saveData()
    }
    
    
    
    func saveData(){
        do{
            try container.viewContext.save()
            fetchApplications() //any time we save we fetch so that savedApplications array is updated
        } catch let error {
            print("Error when saving: \(error)")
        }
    }
    
    func getStatus(jobApp: JobApplication)->String?{
        return jobApp.status
    }
    
    func canUpdateJob(jobApp: JobApplication)->Bool{
        //return false if status is rejected or accepted else true
        return jobApp.status != "Rejected" && jobApp.status != "Accepted"
    }
    
    func canUpdateToInterview(jobApp: JobApplication, newNum:Int)->Bool{
        if jobApp.status == "Applied" {return true}
        
        if let status = jobApp.status{
            if status.contains("Interview"){
                
                //get interview number of current status
                if let num = Int(status.split(separator: " ")[1])
                {
                    if num <= newNum{
                        return true
                    }
                }
        
            }
            
        }
        return false
    }
    //creates and uses predicate from filter command inputted
    func useCommand(inCommand: Command){
        let request = NSFetchRequest<JobApplication>(entityName:"JobApplication")
        
        let filter = inCommand.getPredicate()
        request.predicate = filter
        
        let descriptors = inCommand.getSortDescriptors()
        request.sortDescriptors = descriptors
        do {
            self.applications = try container.viewContext.fetch(request)
            
        } catch let error{
            print("Error when fetching : \(error)")
        }
    }
    
    //returns all applications to a specific company
    func searchAppByName(compName: String)->[JobApplication]{
        
        var companyApps : [JobApplication] = []
        let request = NSFetchRequest<JobApplication>(entityName:"JobApplication")
        
        let filter = NSPredicate(format: "company == %@", compName)
        request.predicate = filter
        
        do {
            
            companyApps = try container.viewContext.fetch(request)
            
        } catch let error{
            print("Error when fetching : \(error)")
        }
        
        return companyApps
    }
    //converts date to string
    func getDateString(date: Date)->String{
        let formatter1 = DateFormatter()
        formatter1.dateStyle = .short
        formatter1.locale = Locale(identifier: "en_US")
        return formatter1.string(from: date)
    }
    
    func getInterviewDate(jobApplication: JobApplication)->String{
        if let dateToReturn = jobApplication.importantDate {
            return getDateString(date: dateToReturn)
        }
        return "N/A"
    }
    
    
    func getRowColor(jobApplication: JobApplication)->Color{
        if jobApplication.status == "Rejected"{
            return Color(#colorLiteral(red: 0.8569247723, green: 0.173017025, blue: 0.08323720843, alpha: 0.2768476837))
        }
        else if jobApplication.status == "Accepted"{
            return Color(#colorLiteral(red: 0, green: 0.7583040595, blue: 0, alpha: 0.1535992266))
        }
        else if let status = jobApplication.status{
            if status.contains("Interview"){
                return Color(#colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 0.5122700874))
            }
        }
        return Color(#colorLiteral(red: 0, green: 0.343914181, blue: 0.928293407, alpha: 0.2785940365))
    }
    
    //calculate top color of an application in its single application view
    func singleViewTopColor(jobApplication: JobApplication)->Color{
        if jobApplication.status == "Rejected"{
            return Color(#colorLiteral(red: 0.5725490451, green: 0, blue: 0.2313725501, alpha: 1))
        }
        else if jobApplication.status == "Accepted"{
            return Color(#colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1))
        }
        
        else if let status = jobApplication.status{
            if status.contains("Interview"){
                return Color(#colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1))
            }
            
        }
        return Color(#colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1))

        
    }
    
    
    
    func createAppForTests(companyName:String, jobTitle:String , dateApplied:Date)->JobApplication{
        let newApp = JobApplication(context: container.viewContext)
        newApp.company = companyName
        newApp.title = jobTitle
        newApp.dateApplied = dateApplied
        newApp.status = "Applied"
        newApp.isFavourite = false
        return newApp
    }
    
}



