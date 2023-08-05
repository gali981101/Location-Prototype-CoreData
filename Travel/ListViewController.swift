//
//  ListViewController.swift
//  Travel
//
//  Created by Terry Jason on 2023/8/2.
//

import UIKit
import CoreData

class ListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var titleArray = [String]()
    private var idArrray = [UUID]()
    
    private var chosenTitle = ""
    private var chosenId : UUID?
    
    private var deleteIndexRow : Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNav()
        setTableView()
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
}

extension ListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        
        var content = cell.defaultContentConfiguration()
        content.text = titleArray[indexPath.row]
        
        cell.contentConfiguration = content
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenTitle = titleArray[indexPath.row]
        chosenId = idArrray[indexPath.row]
        
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let  fetch = fetchData()
            
            deleteIndexRow = indexPath.row
            
            let idString = idArrray[deleteIndexRow!].uuidString
            
            requestFetch(fetch: fetchDataWithId(id: idString), many: false)
        }
    }
    
}

extension ListViewController {
    
    private func setNav() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonClicked))
    }
    
    private func setTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toViewController" {
            let destinationVC = segue.destination as! ViewController
            
            destinationVC.selectedTitle = chosenTitle
            destinationVC.selectedId = chosenId
        }
    }
    
}

extension ListViewController {
    
    private func requestFetch(fetch: NSFetchRequest<NSFetchRequestResult>, many: Bool) {
        do {
            let results = try createContext().fetch(fetch)
            handleResults(results: results, number: many)
        } catch {
            print("錯誤")
        }
    }
    
    private func handleResults(results: [Any], number: Bool) {
        if results.count > 0 {
            for result in results as! [NSManagedObject] {
                setOrDelete(result: result, parameters: number)
            }
        }
    }
    
    private func setOrDelete(result: NSManagedObject, parameters: Bool) {
        if parameters == true {
            setResultValue(result: result)
        } else {
            deleteResult(result: result)
        }
        
        self.tableView.reloadData()
    }
    
    private func setResultValue(result: NSManagedObject) {
        cleanArray()
        
        resultTitle(result: result)
        resultId(result: result)
    }
    
    private func deleteResult(result: NSManagedObject) {
        createContext().delete(result)
        contextSave()
        
        titleArray.remove(at: deleteIndexRow!)
        idArrray.remove(at: deleteIndexRow!)
        
        return
    }
    
    private func resultTitle(result: NSManagedObject) {
        if let title = result.value(forKey: "title") as? String {
            self.titleArray.append(title)
        }
    }
    
    private func resultId(result: NSManagedObject) {
        if let id = result.value(forKey: "id") as? UUID {
            self.idArrray.append(id)
        }
    }
    
    private func cleanArray() {
        self.titleArray.removeAll()
        self.idArrray.removeAll()
    }
    
}

extension ListViewController {
    
    @objc private func getData() {
        requestFetch(fetch: fetchData(), many: true)
    }
    
    @objc func addButtonClicked() {
        chosenTitle = ""
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
}

