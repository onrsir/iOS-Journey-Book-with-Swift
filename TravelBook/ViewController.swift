//
//  ViewController.swift
//  TravelBook
//
//  Created by yeni on 30.10.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{

    @IBOutlet weak var nameText: UITextField!
    
    @IBOutlet weak var commentText: UITextField!
    
    @IBOutlet weak var mapView: MKMapView!
    

    
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                
                pinView?.canShowCallout = true
                pinView?.tintColor = UIColor.black
                
                let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
                pinView?.rightCalloutAccessoryView = button
            } else {
                pinView?.annotation = annotation
            }
        
        return pinView
    }
        
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            
           var requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                
                if let placemark = placemarks {
                    
                    if placemark.count > 0 {
                        
                        let newPlacemark = MKPlacemark(placemark: (placemark[0]))
                        
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                        
                }
               
                }
            }
            
        }
    }
    
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate//shared: paylaşılan
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        
        newPlace.setValue(commentText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatiude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
        }catch {
            print("error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        
        navigationController?.popViewController(animated: true)
        
    }
        
    
    var locationManager = CLLocationManager()
    var chosenLatiude = Double()
    var chosenLongitude = Double()
        
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        // kullanıcının konumunu ne kadar keskinlikte istiyoruz. best: en iyisi fakat çok pil ömrü harcar.
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization() // when ın use authorization: kullanıcının konumunu uygulamayı kullanırken iste
        locationManager.startUpdatingLocation()
        
        
        // gestureRecognizer tıklanınca ne yapılması.
        // long press gestureRecognizer ise uzun basılınca
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        
        gestureRecognizer.minimumPressDuration = 3 // 3sn basınca aktif ol
        
        mapView.addGestureRecognizer(gestureRecognizer)
        
        
        if selectedTitle != "" {
            // boş değilse coredatadan veri çekicez
            
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appdelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleID!.uuidString
            
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString) // istediğim idyi getirtmek için
            
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            
                            if let subtitle = result.value(forKey: "subtitle") as? String {
                                
                                annotationSubtitle = subtitle
                                
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                             let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                        }
                       
                            
                        }
        
                              
                        }
                        
                        }
                    }
                }

            } catch {
                print("error")
            }
            
        } else {
            
        }
        
        
    }
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .began { // // began başladıysa
            
            let touchPoint = gestureRecognizer.location(in: self.mapView) //dokunulan yer
            let touchedCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView) // dokunulan koordinatlar
            chosenLatiude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            
            
            let annotatiton = MKPointAnnotation() //pin oluşturma
            
            
            annotatiton.coordinate = touchedCoordinates
            
            
            if nameText.text == "" {
              
                
                let alert = UIAlertController.init(title: "Upss error!", message: "name enter please", preferredStyle: UIAlertController.Style.alert)
                let okeyButton = UIAlertAction.init(title: "okey", style: UIAlertAction.Style.cancel, handler: nil)
                alert.addAction(okeyButton)

                self.present(alert, animated: true, completion: nil)
                
               
            }
            
            annotatiton.title = nameText.text
            annotatiton.subtitle = commentText.text
            
            self.mapView.addAnnotation(annotatiton)
            
        }

    }
    
    // güncellenen lokasyonları dizi içerisinde bana verir
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
            
        
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude) // enlem ve boylam ister. latitude:enlem longitude:boylam
        
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1) //span zoom yapmak
        let region = MKCoordinateRegion(center: location, span: span) //region: bölge
        
        mapView.setRegion(region, animated: true)
        }

}
    
    

}

