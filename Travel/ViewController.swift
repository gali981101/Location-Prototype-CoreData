//
//  ViewController.swift
//  Travel
//
//  Created by Terry Jason on 2023/8/1.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var noteText: UITextField!
    
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectOrNot = false
    
    var selectedTitle = ""
    var selectedId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDelegate()
        setSaveButton()
        showDetail()
        hideKeyboardWhenTappedAround()
        setLocationManager()
        setLongPressGesture()
    }
    
}

extension ViewController {
    
    private func setDelegate() {
        mapView.delegate = self
        locationManager.delegate = self
    }
    
    private func setLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func setLongPressGesture() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 1
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    private func setSaveButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveButtonClicked))
        navigationItem.rightBarButtonItem?.tintColor = .label
    }
    
    private func saveLocationData() {
        setDataValue(name: nameText.text!, note: noteText.text!, latitude: chosenLatitude, longitude: chosenLongitude)
        saveSuccess()
    }
    
    private func showDetail() {
        if selectedTitle != "" {
            self.navigationItem.rightBarButtonItem = nil
            getDetailData()
        }
    }
    
}

extension ViewController {
    
    private func clean() {
        nameText.text = ""
        noteText.text = ""
        chosenLatitude = Double()
        chosenLongitude = Double()
    }
    
    private func alertAppear() {
        let alert = UIAlertController(title: "Error", message: "請填滿所有空格，並且選取地點", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "立刻照著做", style: .cancel)
        
        alert.addAction(action)
        present(alert, animated: true)
    }
    
    private func saveSuccess() {
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    
}

extension ViewController {
    
    private func getDetailData() {
        do {
            let results = try createContext().fetch(fetchDataWithId(id: selectedId!.uuidString))
            handleFetchResults(results: results)
        } catch {
            print("錯誤")
        }
    }
    
    private func handleFetchResults(results: [Any]) {
        if results.count > 0 {
            for result in results as! [NSManagedObject] {
                setDetailValue(result: result)
            }
        }
    }
    
    private func setDetailValue(result: NSManagedObject) {
        getName(result: result)
    }
    
    private func getName(result: NSManagedObject) {
        if let name = result.value(forKey: "title") as? String {
            annotationTitle = name
            getNote(result: result)
        }
    }
    
    private func getNote(result: NSManagedObject) {
        if let note = result.value(forKey: "subtitle") as? String {
            annotationSubtitle = note
            getlati(result: result)
        }
    }
    
    private func getlati(result: NSManagedObject) {
        if let latitude = result.value(forKey: "latitude") as? Double {
            annotationLatitude = latitude
            getLongit(result: result)
        }
    }
    
    private func getLongit(result: NSManagedObject) {
        if let longitude = result.value(forKey: "longitude") as? Double{
            annotationLongitude = longitude
            
            updateUI()
            
            stopUpdateLocation()
        }
    }
    
    private func updateUI() {
        addAnnota(title: annotationTitle, subTitle: annotationSubtitle, latitude: annotationLatitude, longitude: annotationLongitude)
        setNameAndNoteText()
    }
    
    private func setNameAndNoteText() {
        nameText.text = annotationTitle
        noteText.text = annotationSubtitle
    }
    
    private func stopUpdateLocation() {
        locationManager.stopUpdatingLocation()
        
        spanAndRegion(latitudeDelta: 0.01, longitudeDelta: 0.01, location: create2DCoordinate(latitude: annotationLatitude, longitude: annotationLongitude))
    }
    
}

extension ViewController {
    
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .began {
            
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            
            addAnnota(title: nameText.text!, subTitle: noteText.text!, latitude: chosenLatitude, longitude: chosenLongitude)
            
            selectOrNot = true
            
        }
        
    }
    
    @objc func saveButtonClicked() {
        if nameText.text != "" && noteText.text != "" && selectOrNot == true {
            saveLocationData()
        } else {
            alertAppear()
        }
    }
    
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        
        pinViewIsNil(pinView: &pinView, annotation: annotation, reuseId: reuseId)
        
        return pinView
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
                
                if let placemarks = placemarks {
                    self.placemarksExist(placemarks: placemarks)
                }
            }
        }
    }
    
    private func pinViewIsNil(pinView: inout MKMarkerAnnotationView?, annotation: MKAnnotation, reuseId: String) {
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .label
            
            addPinViewButton(pinView: &pinView)
        } else {
            pinView?.annotation = annotation
        }
    }
    
    private func addPinViewButton(pinView: inout MKMarkerAnnotationView?) {
        let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
        pinView?.rightCalloutAccessoryView = button
    }
    
    private func placemarksExist(placemarks: [CLPlacemark]) {
        if placemarks.count > 0 {
            let newPlacemark = MKPlacemark(placemark: placemarks[0])
            let item = MKMapItem(placemark: newPlacemark)
            item.name = annotationTitle
            
            let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking]
            
            item.openInMaps(launchOptions: launchOptions)
        }
    }
    
}


extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if selectedTitle == "" {
            
            let coordinate = locations[0].coordinate
            
            let location = create2DCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            spanAndRegion(latitudeDelta: 0.01, longitudeDelta: 0.01, location: location)
            
        }
        
    }
    
    private func spanAndRegion(latitudeDelta: Double, longitudeDelta: Double, location: CLLocationCoordinate2D)  {
        
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let region = MKCoordinateRegion(center: location, span: span)
        
        mapView.setRegion(region, animated: true)
        
    }
    
    private func addAnnota(title: String, subTitle: String, latitude: Double, longitude: Double) {
        
        let annotation = MKPointAnnotation()
        let coordinate = create2DCoordinate(latitude: latitude, longitude: longitude)
        
        annotation.title = title
        annotation.subtitle = subTitle
        
        annotation.coordinate = coordinate
        
        self.mapView.addAnnotation(annotation)
        
    }
    
    private func create2DCoordinate(latitude: Double, longitude: Double) -> CLLocationCoordinate2D {
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        return location
    }
    
}

