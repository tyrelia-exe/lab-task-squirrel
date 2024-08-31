//
//  TaskDetailViewController.swift
//  lab-task-squirrel
//
//  Created by Charlie Hieger on 11/15/22.
//

import UIKit
import MapKit
import Photos
import PhotosUI

// TODO: Import PhotosUI

class TaskDetailViewController: UIViewController {

    
    @IBOutlet weak var viewPhoto: UIButton!
    
    @IBOutlet private weak var completedImageView: UIImageView!
    @IBOutlet private weak var completedLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var attachPhotoButton: UIButton!

    // MapView outlet
    @IBOutlet private weak var mapView: MKMapView!

    var task: Task!

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: Register custom annotation view

        // TODO: Set mapView delegate

        // UI Candy
        mapView.layer.cornerRadius = 12


        updateUI()
        updateMapView()
        
        mapView.register(TaskAnnotationView.self, forAnnotationViewWithReuseIdentifier: TaskAnnotationView.identifier)
        mapView.delegate = self
        
    }

    /// Configure UI for the given task
    private func updateUI() {
        titleLabel.text = task.title
        descriptionLabel.text = task.description

        let completedImage = UIImage(systemName: task.isComplete ? "circle.inset.filled" : "circle")

        // calling `withRenderingMode(.alwaysTemplate)` on an image allows for coloring the image via it's `tintColor` property.
        completedImageView.image = completedImage?.withRenderingMode(.alwaysTemplate)
        completedLabel.text = task.isComplete ? "Complete" : "Incomplete"

        let color: UIColor = task.isComplete ? .systemBlue : .tertiaryLabel
        completedImageView.tintColor = color
        completedLabel.textColor = color

        mapView.isHidden = !task.isComplete
        attachPhotoButton.isHidden = task.isComplete
        viewPhoto.isHidden = !task.isComplete

    }

    @IBAction func didTapAttachPhotoButton(_ sender: Any) {
        // TODO: Check and/or request photo library access authorization.
        if PHPhotoLibrary.authorizationStatus(for: .readWrite) != .authorized{
            
            PHPhotoLibrary.requestAuthorization(for: .readWrite){
                [weak self] status in switch status{
                case .authorized:
                    DispatchQueue.main.async{
                        self?.presentImagePicker()
                    }
                default:
                    self?.presentGoToSettingsAlert()
                }
            }
            
        }else{ presentImagePicker()}
        
        

    }

    private func presentImagePicker() {
        // TODO: Create, configure and present image picker.
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        
        config.filter = .images
        
        config.preferredAssetRepresentationMode =  .current
        
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        
        picker.delegate = self
        present(picker, animated: true)

    }

    func updateMapView() {
        // TODO: Set map viewing region and scale
        // Make sure the task has image location.
        guard let imageLocation = task.imageLocation else { return }

        // Get the coordinate from the image location. This is the latitude / longitude of the location.
        // https://developer.apple.com/documentation/mapkit/mkmapview
        let coordinate = imageLocation.coordinate

        // Set the map view's region based on the coordinate of the image.
        // The span represents the maps's "zoom level". A smaller value yields a more "zoomed in" map area, while a larger value is more "zoomed out".
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
        // Add an annotation to the map view based on image location.
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        // TODO: Add annotation to map view
    }
}

// TODO: Conform to PHPickerViewControllerDelegate + implement required method(s)

// TODO: Conform to MKMapKitDelegate + implement mapView(_:viewFor:) delegate method.
extension TaskDetailViewController: MKMapViewDelegate {
    // Implement mapView(_:viewFor:) delegate method.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        // Dequeue the annotation view for the specified reuse identifier and annotation.
        // Cast the dequeued annotation view to your specific custom annotation view class, `TaskAnnotationView`
        // 💡 This is very similar to how we get and prepare cells for use in table views.
        guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: TaskAnnotationView.identifier, for: annotation) as? TaskAnnotationView else {
            fatalError("Unable to dequeue TaskAnnotationView")
        }

        // Configure the annotation view, passing in the task's image.
        annotationView.configure(with: task.image)
        return annotationView
    }
}
// Helper methods to present various alerts
extension TaskDetailViewController : PHPickerViewControllerDelegate{
    /// Presents an alert notifying user of photo library access requirement with an option to go to Settings in order to update status.
    func presentGoToSettingsAlert() {
        let alertController = UIAlertController (
            title: "Photo Access Required",
            message: "In order to post a photo to complete a task, we need access to your photo library. You can allow access in Settings",
            preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }

        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    /// Show an alert for the given error
    private func showAlert(for error: Error? = nil) {
        let alertController = UIAlertController(
            title: "Oops...",
            message: "\(error?.localizedDescription ?? "Please try again...")",
            preferredStyle: .alert)

        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)

        present(alertController, animated: true)
    }
    
 
    func picker (_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]){
        picker.dismiss(animated: true)
        
        let result = results.first
        guard let assetID = result?.assetIdentifier,
              let location = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil).firstObject?.location else{
            return 
        }
        guard let provider = result?.itemProvider,
              // Make sure the provider can load a UIImage
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        // Load a UIImage from the provider
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in

            // Handle any errors
            if let error = error {
              DispatchQueue.main.async { [weak self] in self?.showAlert(for:error) }
            
            }

            // Make sure we can cast the returned object to a UIImage
            guard let image = object as? UIImage else { return }

            print("🌉 We have an image!")

            // UI updates should be done on main thread, hence the use of `DispatchQueue.main.async`
            DispatchQueue.main.async { [weak self] in

                // Set the picked image and location on the task
                self?.task.set(image, with: location)

                // Update the UI since we've updated the task
                self?.updateUI()

                // Update the map view since we now have an image an location
                self?.updateMapView()
            }
        }
        Swift.print("Image Location coordinate: \(location.coordinate)")
        }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

            // Segue to Detail View Controller
         if segue.identifier == "PhotoSegue" {
             if let photoViewController = segue.destination as? PhotoViewController {
                 photoViewController.task = task
              }
          }
      }
}
