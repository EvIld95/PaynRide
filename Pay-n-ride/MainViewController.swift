//
//  ViewController.swift
//  Pay-n-ride
//
//  Created by Paweł Szudrowicz on 16.03.2018.
//  Copyright © 2018 Paweł Szudrowicz. All rights reserved.
//

import UIKit
import Socket
import M13ProgressSuite
import MapKit

class MainViewController: UIViewController {
    var mySocket = try! Socket.create()
    var locationManager = CLLocationManager()
    var savedLocations = [CLLocation]()
    
    var containerView = UIView()
    
    let batteryImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = #imageLiteral(resourceName: "battery").withRenderingMode(.alwaysOriginal)
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    let currentImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = #imageLiteral(resourceName: "power").withRenderingMode(.alwaysOriginal)
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    let rpmImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = #imageLiteral(resourceName: "speed").withRenderingMode(.alwaysOriginal)
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    lazy var progressBatteryView : M13ProgressViewBorderedBar = {
        let bv = M13ProgressViewBorderedBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        bv.cornerType = M13ProgressViewBorderedBarCornerTypeRounded
        bv.cornerRadius = 8.0
        bv.animationDuration = 0.25
        bv.primaryColor = UIColor.rgb(red: 157, green: 213, blue: 192)
        bv.secondaryColor = .clear
        bv.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        bv.clipsToBounds = true
        bv.layer.cornerRadius = 10.0
        
        return bv
    }()
    
    lazy var progressRPMView : M13ProgressViewBorderedBar = {
        let bv = M13ProgressViewBorderedBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        bv.cornerType = M13ProgressViewBorderedBarCornerTypeRounded
        bv.cornerRadius = 8.0
        bv.animationDuration = 0.25
        bv.primaryColor = UIColor.rgb(red: 250, green: 193, blue: 115)
        bv.secondaryColor = .clear
        bv.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        bv.clipsToBounds = true
        bv.layer.cornerRadius = 10.0
        return bv
    }()
    
    lazy var progressCurrentView : M13ProgressViewBorderedBar = {
        let bv = M13ProgressViewBorderedBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        bv.cornerType = M13ProgressViewBorderedBarCornerTypeRounded
        bv.cornerRadius = 8.0
        bv.animationDuration = 0.25
        bv.primaryColor = UIColor.rgb(red: 241, green: 100, blue: 108)
        bv.secondaryColor = .clear
        bv.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        bv.clipsToBounds = true
        bv.layer.cornerRadius = 10.0
        return bv
    }()
    
    let infoLabel : UILabel = {
        let label = UILabel()
     
        let attributedText = NSMutableAttributedString(string: "Estimated distance to cover:", attributes: [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.black])
        attributedText.append(NSAttributedString(string: " 18km", attributes: [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.orange]))
        attributedText.append(NSAttributedString(string: "\nEstimated time of ride:", attributes: [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.black]))
        attributedText.append(NSAttributedString(string: " 40min", attributes: [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.orange]))
        label.attributedText = attributedText
        label.textAlignment = .center
        label.numberOfLines = 0
        
        return label
    }()
    
    lazy var mapView: MKMapView = {
        let mv = MKMapView()
        mv.delegate = self
        return mv
    }()
    
    let skateboardImageView: UIImageView = {
        let iv = UIImageView(image: #imageLiteral(resourceName: "skateboard").withRenderingMode(.alwaysOriginal))
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
    
        return iv
    }()
    
    let boardStatus: UILabel = {
        let label = UILabel()
        let attributedText = NSMutableAttributedString(string: "Connection:", attributes: [.font: UIFont.boldSystemFont(ofSize: 18), .foregroundColor: UIColor.black])
        attributedText.append(NSAttributedString(string: "ACTIVE", attributes: [.font: UIFont.boldSystemFont(ofSize: 18), .foregroundColor: UIColor.orange]))
        attributedText.append(NSAttributedString(string: "\nRiding Mode:", attributes: [.font: UIFont.boldSystemFont(ofSize: 18), .foregroundColor: UIColor.black]))
        attributedText.append(NSAttributedString(string: " PRO", attributes: [.font: UIFont.boldSystemFont(ofSize: 18), .foregroundColor: UIColor.rgb(red: 241, green: 100, blue: 108)]))
        label.attributedText = attributedText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 3.0
        locationManager.requestAlwaysAuthorization()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        if mySocket.isConnected == false {
//            mySocket.readBufferSize = 60
//            try! mySocket.connect(to: "192.168.1.17", port: 1246)
//        }
        
        
    
    }

    @objc func appMovedToBackground() {
        mySocket.close()
        print("Background")
    }
    
    @objc func appMovedToForeground() {
        mySocket = try! Socket.create()
        if mySocket.isConnected == false {
            mySocket.readBufferSize = 60
            try! mySocket.connect(to: "192.168.1.17", port: 1246)
        }
        print("Foregorund")
    }
    
    var progress: CGFloat = 0.0
    var up = false
    var locationBeginTouch: CGFloat?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first?.location(in: self.view)
        guard location!.y < self.mapView.frame.origin.y else { return }
        locationBeginTouch = location?.y
        let constraint = self.view.constraints.filter { (constraint) -> Bool in
            return constraint.identifier == "topConstraint"
            }.first!
        animatorUp = AnimatorManager.showMapView(view: self.view)
        animatorDown =  AnimatorManager.hideMapView(view: self.view)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let locationBegin = locationBeginTouch else { return }
        
        let location = touches.first?.location(in: self.view)
        if -(location!.y - locationBegin) > 0.0 {
            up = true
            progress = max(0.01,min((-(location!.y - locationBegin) / 200.0),0.99))
            animatorUp!.fractionComplete = progress
        } else if -(location!.y - locationBegin) < 0.0  {
            up = false
            progress = max(0.01,min(((location!.y - locationBegin) / 200.0),0.99))
            animatorDown!.fractionComplete = progress
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if progress > 0.4 && up {
            animatorUp?.startAnimation()
        } else if progress <= 0.4 && up {
            animatorUp?.isReversed = true
            animatorUp?.startAnimation()
        } else if progress > 0.4 && !up {
            animatorDown?.startAnimation()
        } else if progress <= 0.4 && !up {
            animatorDown?.isReversed = true
            animatorDown?.startAnimation()
        }
        locationBeginTouch = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupViews()
        self.setupLocationManager()
        self.setupNavigationController()
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
        
        //self.readDataFromBoard()
        self.view.constraints.forEach { (constraint) in
            if constraint.firstItem === self.mapView && constraint.firstAttribute == NSLayoutAttribute.top {
                constraint.constant = 400
                constraint.identifier = "topConstraint"
                return
            }
        }
        
        
    }
    
    func setupNavigationController() {
        self.navigationItem.title = "Board Panel"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 212.0/255.0, green: 170.0/255.0, blue: 125.0/255.0, alpha: 1.0)
    }


    var bottomConstraint: NSLayoutConstraint?
    var animatorUp : UIViewPropertyAnimator?
    var animatorDown : UIViewPropertyAnimator?
    
    private func handleSwipeDown() {
        let constraint = self.view.constraints.filter { (constraint) -> Bool in
            return constraint.identifier == "topConstraint"
            }.first!
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            constraint.constant = 400
            
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
  
    private func readDataFromBoard() {
        DispatchQueue.global(qos: .background).async { [unowned self] in
            while(true) {
                guard self.mySocket.isConnected else  { continue }
                guard let response = try? self.mySocket.readString() else { continue }
                guard let resp = response else { continue }

                DispatchQueue.main.async {
                    let values = resp.components(separatedBy: "!")
                    for value in values[0..<values.count-1] {
                        let cleanData = value.components(separatedBy: " ")
                        guard cleanData.count > 1 else {
                            continue
                        }
                        let name = cleanData[0]
                        let valueString = cleanData[1]
                        
                        if(name == "v_in") {
                            if let valueBattery = Float(valueString) {
                                DispatchQueue.main.async {
                                    self.progressBatteryView.setProgress(CGFloat((valueBattery-28)/(5.0)), animated: true)
                                }
                            }
                        } else if(name == "rpm") {
                            if let valueRPM = Float(valueString) {
                                DispatchQueue.main.async {
                                    self.progressRPMView.setProgress(CGFloat(abs(valueRPM)/50000.0), animated: true)
                                }
                            }
                        } else if(name == "current_motor") {
                            if let valueCurrent = Float(valueString) {
                                DispatchQueue.main.async {
                                    self.progressCurrentView.setProgress(CGFloat(valueCurrent/40.0), animated: true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func setupViews() {
        self.view.backgroundColor = UIColor.rgb(red: 239, green: 208, blue: 158)
        let batteryStackView = UIStackView(arrangedSubviews: [batteryImageView, progressBatteryView])
        let currentStackView = UIStackView(arrangedSubviews: [currentImageView, progressCurrentView])
        let rpmStackView = UIStackView(arrangedSubviews: [rpmImageView, progressRPMView])
        batteryStackView.distribution = .fill
        batteryStackView.spacing = 20
        batteryStackView.axis = .horizontal
        
        currentStackView.distribution = .fill
        currentStackView.spacing = 20
        currentStackView.axis = .horizontal
        
        rpmStackView.distribution = .fill
        rpmStackView.spacing = 20
        rpmStackView.axis = .horizontal
        
        let stackView = UIStackView(arrangedSubviews: [batteryStackView,currentStackView,rpmStackView])
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        stackView.axis = .vertical
        progressCurrentView.setProgress(0.2, animated: true)
        progressBatteryView.setProgress(0.75, animated: true)
        progressRPMView.setProgress(0.4, animated: true)
        
        
        self.view.addSubview(stackView)
        self.view.addSubview(infoLabel)

        self.view.addSubview(containerView)
        self.view.addSubview(mapView)
        self.containerView.addSubview(skateboardImageView)
        self.containerView.addSubview(boardStatus)
        
        batteryImageView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        currentImageView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        rpmImageView.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 50, height: 50)
        stackView.anchor(top: self.view.safeAreaLayoutGuide.topAnchor, left: self.view.safeAreaLayoutGuide.leftAnchor, bottom: nil, right: self.view.safeAreaLayoutGuide.rightAnchor, paddingTop: 40, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 200)
        
        infoLabel.anchor(top: stackView.bottomAnchor, left: self.view.safeAreaLayoutGuide.leftAnchor, bottom: nil, right: self.view.safeAreaLayoutGuide.rightAnchor, paddingTop: 20, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 50)
        
        containerView.anchor(top: infoLabel.bottomAnchor, left: self.view.safeAreaLayoutGuide.leftAnchor, bottom: self.view.bottomAnchor, right: self.view.safeAreaLayoutGuide.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        mapView.anchor(top: infoLabel.bottomAnchor, left: self.view.safeAreaLayoutGuide.leftAnchor, bottom: nil, right: self.view.safeAreaLayoutGuide.rightAnchor, paddingTop: 400, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        mapView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 1.0).isActive = true
        
        skateboardImageView.anchor(top: self.containerView.topAnchor, left: self.containerView.leftAnchor, bottom: self.containerView.bottomAnchor, right: nil, paddingTop: 20, paddingLeft: 20, paddingBottom: 50, paddingRight: 0, width: self.view.frame.width/3, height: 0)
        
        boardStatus.anchor(top: self.containerView.topAnchor, left: nil, bottom: self.containerView.bottomAnchor, right: self.containerView.rightAnchor, paddingTop: 20, paddingLeft: 0, paddingBottom: 50, paddingRight: 20, width: 0, height: 0)
        
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            batteryStackView.frame.origin.x += 50
        }, completion: nil)
        
        UIView.animate(withDuration: 1.0, delay: 0.2, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            rpmStackView.frame.origin.x -= 50
        }, completion: nil)
        
        UIView.animate(withDuration: 1.0, delay: 0.1, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            currentStackView.frame.origin.x += 50
        }, completion: nil)
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.toValue = 2 * Float.pi
        rotationAnimation.duration = 0.5
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        self.batteryImageView.layer.add(rotationAnimation, forKey: nil)
        rotationAnimation.beginTime = CACurrentMediaTime() + 0.1
        self.currentImageView.layer.add(rotationAnimation, forKey: nil)
        rotationAnimation.beginTime = CACurrentMediaTime() + 0.2
        self.rpmImageView.layer.add(rotationAnimation, forKey: nil)
    }

}

extension MainViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            print("AuthorizationAlways")
            mapView.showsUserLocation = true
            locationManager.startUpdatingLocation()
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        let center = CLLocationCoordinate2D(latitude: newLocation.coordinate.latitude, longitude: newLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
        
        print("\(newLocation.horizontalAccuracy) | \(self.locationManager.desiredAccuracy)")
        
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        if newLocation.speed < 0 {
            return
        }
        
        if newLocation.horizontalAccuracy < 20.0 {
//            if self.savedLocations.count > 0 {
//                distance += newLocation.distance(from: self.savedLocations.last!)
//            }
            print("Saved location")
            self.savedLocations.append(newLocation)
//            if(newLocation.speed > 0) {
//                self.currentSpeed = newLocation.speed * 3.6
//            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}


extension MainViewController: MKMapViewDelegate {
    
    func mapRegion() -> MKCoordinateRegion {
        let initialLoc = savedLocations.first!
        
        var minLat = initialLoc.coordinate.latitude
        var minLng = initialLoc.coordinate.longitude
        var maxLat = minLat
        var maxLng = minLng
        
        for location in savedLocations {
            minLat = min(minLat, location.coordinate.latitude)
            minLng = min(minLng, location.coordinate.longitude)
            maxLat = max(maxLat, location.coordinate.latitude)
            maxLng = max(maxLng, location.coordinate.longitude)
        }
        
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: (minLat + maxLat)/2, longitude: (minLng + maxLng)/2),span: MKCoordinateSpan(latitudeDelta: (maxLat - minLat)*1.1, longitudeDelta: (maxLng - minLng)*1.1))
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polyline = overlay as! MKPolyline
        
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = UIColor.red
        renderer.lineCap = .round
        renderer.lineWidth = 2
        return renderer
    }
    
    func polyline() -> MKPolyline {
        var coords = [CLLocationCoordinate2D]()
        
        for location in savedLocations {
            coords.append(location.coordinate)
        }
        
        return MKPolyline(coordinates: &coords, count: savedLocations.count)
    }
    
    func loadMap() {
        if savedLocations.count > 0 {
            mapView.region = mapRegion()
            mapView.add(polyline())
            
        } else {
            print("ERROR with map")
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        
        var reuseIdentifier = "pinItem"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)

        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView!.canShowCallout = true
            annotationView!.isEnabled = true

            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 120, height: 40))
            label.text = "Time"

            annotationView!.rightCalloutAccessoryView = label

        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("Did update user location")
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("Select")
    }
}
