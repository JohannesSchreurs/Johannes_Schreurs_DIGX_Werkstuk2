//
//  ViewController.swift
//  Johannes_Schreurs_Werkstuk2
//
//  Created by Johannes Schreurs on 31/05/2018.
//  Copyright © 2018 Johannes Schreurs. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var myMapView: MKMapView!
    @IBOutlet weak var updateTextLable: UILabel!
    @IBOutlet weak var updateLabel: UILabel!
    
    @IBAction func refresh(_ sender: Any) {
        refresh()
    }
    
    @IBAction func langChange(_ sender: Any) {
        let alertController = UIAlertController(title: NSLocalizedString("modal_title", comment: ""), message:
            NSLocalizedString("modal_body", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("dismiss", comment: ""), style: UIAlertActionStyle.default,handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBOutlet weak var myButton: UIButton!
    @IBOutlet weak var myLangButton: UIButton!
    
    var locationManager = CLLocationManager()
    
    let url = URL(string: "https://api.jcdecaux.com/vls/v1/stations?apiKey=6d5071ed0d0b3b68462ad73df43fd9e5479b03d6&contract=Bruxelles-Capitale")
    
    var stations = Array<Station>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
       
        self.updateTextLable.text = NSLocalizedString("update", comment: "")
        self.myButton.setTitle(NSLocalizedString("refresh", comment: ""), for: .normal)
        self.myLangButton.setTitle(NSLocalizedString("lang", comment: ""), for: .normal)
        
        refresh()
        //Map functions
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    //This function will do the following:
    //1: Connect to the API.
    //2: Try to get all the data from our CD.
    //2.1: If there IS data in our CD, we will push every station into an array.
    //2.2: If there is NO data in our CD, we will get all the stations from the API and push them into CD.
    //2.2.1: After that we push every station into an array.
    //3: We add annotations to every station with the showAnnotationsOnMap() function. I do this because
    //   I need to validate that our data is succesfully loaded.
    func fetchStationsAndAddToCoreData(){
        let urlRequest = URLRequest(url: self.url!)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
            else{
                return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Station")
        request.returnsObjectsAsFaults = false
        
        do{
            let alleStations = try managedContext.fetch(request) as! [Station]
            //Check if our Core Data is empty. If it isn't, we push our data to the Core Data
            if alleStations.count > 0 {
                for station in alleStations{
                    self.stations.append(station)
                }
            } else {
                DispatchQueue.main.async {
                    let task = session.dataTask(with: urlRequest){
                        (data, response, error) in
                        guard error == nil else{
                            print("Error, cannot get JSON")
                            print(error!)
                            return
                        }
                        
                        guard let responseData = data else{
                            print("Error, data was not received")
                            return
                        }
                        
                        let json = try! JSONSerialization.jsonObject(with: responseData, options: []) as! NSArray
                        
                        for obj in json {
                            let station = NSEntityDescription.insertNewObject(forEntityName: "Station", into: managedContext) as! Station
                            
                            let name = (obj as! NSDictionary)
                            let pos = ((obj as! NSDictionary).value(forKey: "position")) as! NSDictionary
                            
                            let stationToCoreData = MyStation(number: (name.value(forKey: "number") as? Int64)!, name: name.value(forKey: "name") as! String, address: name.value(forKey: "address") as! String, coordinate: CLLocationCoordinate2D(latitude: pos.value(forKey: "lat") as! CLLocationDegrees, longitude: pos.value(forKey: "lng") as! CLLocationDegrees), banking: (name.value(forKey: "banking") as! Bool), bonus: (name.value(forKey: "bonus") as! Bool), contractName: name.value(forKey: "contract_name") as! String, bikeStands: (name.value(forKey: "bike_stands") as? Int64)!, availableBikeStands: (name.value(forKey: "available_bike_stands") as? Int64)!, availableBikes: (name.value(forKey: "available_bikes") as? Int64)!, lastUpdate: (name.value(forKey: "last_update") as? Int64)!, status: name.value(forKey: "status") as! String)
                            
                            station.number = stationToCoreData.number!
                            station.name = stationToCoreData.name
                            station.address = stationToCoreData.address
                            station.latitude = Double(stationToCoreData.coordinate.latitude)
                            station.longitude = Double(stationToCoreData.coordinate.longitude)
                            station.banking = stationToCoreData.banking!
                            station.bonus = stationToCoreData.bonus!
                            station.contractName = stationToCoreData.contractName
                            station.bikeStands = stationToCoreData.bikeStands!
                            station.availableBikeStands = stationToCoreData.availableBikeStands!
                            station.availableBikes = stationToCoreData.availableBikes!
                            station.lastUpdate = stationToCoreData.lastUpdate!
                            station.status = stationToCoreData.status!
                            
                            self.stations.append(station)
                        }
                        //End of JSONloop
                        do{
                            try managedContext.save()
                            //Now that we have the stations, we can add annotations to our map
                            self.showStationsOnMap()
                        } catch {
                            fatalError("Failure to save the context: \(error)")
                        }
                        //End of try/Catch
                    }
                    //End of task
                    task.resume()
                }
                //End of async

            }
            //End of Else statement
        }
        //End of do
        catch{
            fatalError("Couldn't find \(error)")
        }
        //End of catch
    }
    //End function
    
    func showStationsOnMap(){
        for station in stations{
            DispatchQueue.main.async{
                let coordinate:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: station.latitude, longitude: station.longitude)
                
                var subTitelStatus:String?
                var subTitelFietsen = "\n" + NSLocalizedString("bikes_available", comment: "") + String(station.availableBikes) + "/" + String(station.bikeStands)
                var subTitelBonus:String?
                
                if(station.bonus){
                    subTitelBonus = "\n" + NSLocalizedString("bonus", comment: "")
                } else{
                    subTitelBonus = "\n" + NSLocalizedString("no_bonus", comment: "")
                }
                
                if(station.status == "OPEN"){
                    subTitelStatus = NSLocalizedString("open", comment: "")
                } else{
                    subTitelStatus = NSLocalizedString("closed", comment: "")
                    subTitelFietsen = "\n" + NSLocalizedString("no_bikes_available", comment: "")
                }
                
                let subtitle = subTitelStatus! + subTitelFietsen + subTitelBonus!
                
                let annotation = StationAnnotation(coordinate: coordinate, title: station.name!, subtitle: subtitle)
                
                self.myMapView.addAnnotation(annotation)
            }
        }
    }
    
    func deleteAllAnnotations(){
        self.myMapView.removeAnnotations(self.myMapView.annotations)
    }
    
    func deleteAllData(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
            else {
                return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Station")
        request.returnsObjectsAsFaults = false
        do {
            let results = try managedContext.fetch(request)
            for managedObject in results {
                let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
                managedContext.delete(managedObjectData)
            }
        } catch let error as NSError {
            print("\(error) \(error.userInfo)")
        }
    }
    
    func refresh(){
        deleteAllData()
        stations = []
        deleteAllAnnotations()
        fetchStationsAndAddToCoreData()
        let timestamp = DateFormatter()
        timestamp.dateStyle = .short
        timestamp.timeStyle = .medium
        timestamp.locale = Locale(identifier: "en_GB")
        updateLabel.text = timestamp.string(from: NSDate() as Date)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
    }
}


