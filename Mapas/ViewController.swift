//
//  ViewController.swift
//  Mapas
//
//

import UIKit
import MapKit

class ViewController: UIViewController {

    var manager = CLLocationManager()
    var latitud : CLLocationDegrees!
    var longitud : CLLocationDegrees!
    
    var latDestination : CLLocationDegrees!
    var longDestination : CLLocationDegrees!
    
    @IBOutlet weak var SearchBar: UISearchBar!
    @IBOutlet weak var MapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
        
        SearchBar.delegate = self
    }
    
    @IBAction func getLocalitation(_ sender: UIButton) {
        // Alerta para mostrar la longitud y latitud
        let alert = UIAlertController(title: "Ubicacion", message: "Las coordenadas de tu ubicacion son: \(latitud!) , \(longitud!)", preferredStyle: .alert)
        
        // Boton aceptar en el alert
        let actionAceptar = UIAlertAction(title: "Aceptar", style: .default) { (_) in
            self.dismiss(animated: true, completion: nil)
        }
        
        // Alerta para ver mas cerca el mapa
        let accionVerMas = UIAlertAction(title: "Ver mas", style: .default) { (_) in
            // Localicacion en el mapa
            let localizacion = CLLocationCoordinate2DMake(self.latitud, self.longitud)
            
            // Mostrar mas cerca o mas lejos al acercar a la ubicacion
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.01)
            
            // Region donde esta el usuario
            let region = MKCoordinateRegion(center: localizacion, span: span)
            
            self.MapView.setRegion(region, animated: true)
            self.MapView.showsUserLocation = true
        }
        // Mostrar Alerts
        alert.addAction(actionAceptar)
        alert.addAction(accionVerMas)
        present(alert, animated: true, completion: nil)
    }
}

extension ViewController: UISearchBarDelegate, CLLocationManagerDelegate {
    // Funcion para buscar en la barra
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Ocultar la el teclado de la barra de busqueda
        SearchBar.resignFirstResponder()
        
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(SearchBar.text!) { (places:[CLPlacemark]?, error: Error?) in
            
            if error == nil {
                let place = places?.first
                
                let anotation = MKPointAnnotation()
                anotation.coordinate = (place?.location?.coordinate)!
                anotation.title = self.SearchBar.text
                
                self.latDestination = anotation.coordinate.latitude
                self.longDestination = anotation.coordinate.longitude
                
                let myLocation = CLLocation(latitude: self.latitud, longitude: self.longitud)
                let myNextDestination = CLLocation(latitude: self.latDestination, longitude: self.longDestination)
                
                //Finding my distance to my next destination (in km)
                let distance = myLocation.distance(from: myNextDestination) / 1000
                let distanceFormat = String(format: "%.2f", distance)
                
                let span = MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.02)
                let region = MKCoordinateRegion(center: anotation.coordinate, span: span)
                
                self.MapView.setRegion(region, animated: true)
                self.MapView.addAnnotation(anotation)
                self.MapView.selectAnnotation(anotation, animated: true)
                
                // Alerta para mostrar la longitud y latitud
                let alert = UIAlertController(title: "Distancia", message: "La distancia entre tu ubicacion y tu busqueda es de \(distanceFormat) km", preferredStyle: .alert)
                
                // Boton aceptar en el alert
                let actionAceptar = UIAlertAction(title: "Aceptar", style: .default) { (_) in
                    self.dismiss(animated: true, completion: nil)
                }
                
                // Alerta para ver la ruta el mapa
                let accionRuta = UIAlertAction(title: "Trazar ruta", style: .default) { (_) in
                    ruta()
                }
                
                // Mostrar Alerts
                alert.addAction(actionAceptar)
                alert.addAction(accionRuta)
                self.present(alert, animated: true, completion: nil)
                
            } else {
                print("Error al realizar la busqueda \(String(describing: error?.localizedDescription))")
                
                // Alerta para mostrar la longitud y latitud
                let alert = UIAlertController(title: "Error", message: "Error al realizar la busqueda", preferredStyle: .alert)
                
                // Boton aceptar en el alert
                let actionAceptar = UIAlertAction(title: "Aceptar", style: .default) { (_) in
                    self.dismiss(animated: true, completion: nil)
                }
                
                // Mostrar Alerts
                alert.addAction(actionAceptar)
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        func ruta() {
            // Mostrar ruta
            let sourceLocation = CLLocationCoordinate2D(latitude: self.latitud, longitude: self.longitud)
            let destinationLocation = CLLocationCoordinate2D(latitude: self.latDestination, longitude: self.longDestination)
            
            // 3.
            let sourcePlacemark = MKPlacemark(coordinate: sourceLocation)
            let destinationPlacemark = MKPlacemark(coordinate: destinationLocation)

            // 4.
            let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
            let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
            
            // 5.
            let sourceAnnotation = MKPointAnnotation()
            sourceAnnotation.title = "Origen"

            if let location = sourcePlacemark.location {
                sourceAnnotation.coordinate = location.coordinate
            }

            let destinationAnnotation = MKPointAnnotation()
            destinationAnnotation.title = "Destino"

            if let location = destinationPlacemark.location {
                destinationAnnotation.coordinate = location.coordinate
            }

            // 6.
            self.MapView.showAnnotations([sourceAnnotation, destinationAnnotation], animated: true )

            // 7.
            let directionRequest = MKDirections.Request()
            directionRequest.source = sourceMapItem
            directionRequest.destination = destinationMapItem
            directionRequest.transportType = .automobile
            directionRequest.requestsAlternateRoutes = true
            
            // Calculate the direction
            let directions = MKDirections(request: directionRequest)

            // 8.
            directions.calculate { (response, error) -> Void in
                guard let response = response else {
                    if let error = error {
                        print("Error: \(error)")
                    }
                    return
                }

                let route = response.routes[0]
                self.MapView.addOverlay((route.polyline))
                self.MapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
            
            func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
                let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
                renderer.strokeColor = .blue
                return renderer
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("Locations.first \(locations.first!)")
            self.latitud = location.coordinate.latitude
            self.longitud = location.coordinate.longitude
        }
    }
}
