//
//  ListViewController.swift
//  TravelBook
//
//  Created by yeni on 31.10.2022.
//

import UIKit
import CoreData

class ListViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var titleArray = [String]()
    var idArray = [UUID]()
    
    var choosenTitle = ""
    var choosenTitleID : UUID?
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            
            let idString = idArray[indexPath.row].uuidString
            
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
            let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    
                    for result in results as! [NSManagedObject] {
                        
                        if let id = result.value(forKey: "id") as? UUID {
                            
                            if id == idArray[indexPath.row] {
                                context.delete(result)
                                titleArray.remove(at: indexPath.row)
                                idArray.remove(at: indexPath.row)
                                self.tableView.reloadData()
                                
                                do {
                                    try context.save()
                                    
                                } catch {
                                    print("error")
                                }
                                
                                break
                                
                            }
                            
                        }
                        
                        
                    }
                    
                    
                }
            } catch {
                print("error")
            }
            
            
            
            
        }
    }
    
    
    
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getdata), name: NSNotification.Name("newPlace"), object: nil)
    
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicek))
        
        tableView.dataSource = self
        tableView.delegate = self
        
        getdata()
        
    }
    
    @objc func getdata(){
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(request)
            if results.count > 0 {
                
                self.titleArray.removeAll(keepingCapacity:false)
                self.idArray.removeAll(keepingCapacity: false)
                
                
                for result in results as! [NSManagedObject] {
                    
                  if let title = result.value(forKey: "title") as? String {
                      self.titleArray.append(title)
                        
                    }
                    if let id = result.value(forKey: "id") as? UUID {
                        
                        self.idArray.append(id)
                            
                    }
                    tableView.reloadData()
                }
            }
            
        } catch {
            print("error")
        }
        
    }
    
    @objc func   addButtonClicek() {
        choosenTitle = ""
        performSegue(withIdentifier: "toViewController", sender: nil)
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = titleArray[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        choosenTitle = titleArray[indexPath.row]
        choosenTitleID = idArray[indexPath.row]
        performSegue(withIdentifier: "toVievControllers", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toVievControllers" {
            let destiantionVC = segue.destination as! ViewController
            destiantionVC.selectedTitle = choosenTitle
            destiantionVC.selectedTitleID = choosenTitleID
            
        }
    }
}
