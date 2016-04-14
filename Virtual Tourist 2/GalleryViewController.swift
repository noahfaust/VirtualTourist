//
//  GalleryViewController.swift
//  Virtual Tourist 2
//
//  Created by Alexandre Gonzalo on 26/3/2016.
//  Copyright © 2016 Agito Cloud. All rights reserved.
//

import Foundation
import MapKit
import UIKit
import CoreData

class GalleryViewController: UIViewController {
    
    var location: Location!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var refreshButton: UIBarButtonItem!
    var deleteButton: UIBarButtonItem!
    
    var state: State = .ViewMode
    var shouldReloadCollectionView = false
    var newIndexPaths = [NSIndexPath]()
    var updatedIndexPaths = [NSIndexPath]()
    var deletedIndexPaths = [NSIndexPath]()
    var movedIndexPaths = [[String : NSIndexPath]]()
    let space: CGFloat = 6.0
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
        
        refreshButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: #selector(GalleryViewController.refreshButtonTouchUp))
        deleteButton = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: #selector(GalleryViewController.deleteButtonTouchUp))
        navigationItem.rightBarButtonItem = refreshButton
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print(error)
        }
        fetchedResultsController.delegate = self
        
        mapView.addAnnotation(location)
        mapView.setRegion(MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: CLLocationDegrees(0.1), longitudeDelta: CLLocationDegrees(0.1))), animated: true)
        mapView.scrollEnabled = false
        mapView.rotateEnabled = false
        
        markDownloadedPhoto()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let fetchedObjects = fetchedResultsController.fetchedObjects where fetchedObjects.isEmpty {
            downloadNewPhotos()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController.delegate = nil
    }
    
    // MARK: - View Actions & Functions
    
    func refreshButtonTouchUp() {
        print("refreshButtonTouchUp")
        setState(.Loading)
        for o in fetchedResultsController.fetchedObjects! {
            sharedContext.deleteObject(o as! Photo)
        }
        downloadNewPhotos()
    }
    
    func deleteButtonTouchUp() {
        print("deleteButtonTouchUp")
        setState(.Deleting)
        if let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems() {
            for i in indexPathsForSelectedItems {
                let photo = fetchedResultsController.objectAtIndexPath(i) as! Photo
                dispatch_async(dispatch_get_main_queue()) {
                    self.sharedContext.deleteObject(photo)
                }
            }
            saveContext()
        }
    }
    
    func downloadNewPhotos() {
        let client = FlickrClient.sharedInstance()
        client.getLocationPhotos(location) { success, errorString in
            self.saveContext()
        }
    }
    
    func setState(newState: State) {
        if state != newState {
            switch newState {
            case .ViewMode:
                if !isLoading() {
                    print("setState Viewing")
                    state = .ViewMode
                    dispatch_async(dispatch_get_main_queue()) {
                        self.navigationItem.rightBarButtonItem = self.refreshButton
                        self.navigationItem.rightBarButtonItem!.enabled = true
                    }
                } else {
                    print("setState still loading")
                    setState(.Loading)
                }
            case .Loading, .Deleting:
                print("setState Loading")
                state = newState
                dispatch_async(dispatch_get_main_queue()) {
                    self.navigationItem.rightBarButtonItem!.enabled = false
                }
            case .DeletionMode:
                print("setState DeletionMode")
                state = .DeletionMode
                dispatch_async(dispatch_get_main_queue()) {
                    self.navigationItem.rightBarButtonItem = self.deleteButton
                    self.navigationItem.rightBarButtonItem!.enabled = true
                }
            }
        }
    }
    
    func isLoading() -> Bool {
        
        for c in collectionView.visibleCells() {
            if let photo = fetchedResultsController.fetchedObjects![(collectionView.indexPathForCell(c)!.item)] as? Photo {
                if !photo.imageDownloaded {
                    return true
                }
            }
        }
        print("collection is complete")
        return false
    }
    
    func markDownloadedPhoto() {
        for o in fetchedResultsController.fetchedObjects as! [Photo] {
            if o.imagePath != nil {
                o.imageDownloaded = true
            }
        }
    }
    
    // MARK: - Core Data convenience methods
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    // MARK: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        // Create the fetch request
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        // Add a sort descriptor. This enforces a sort order on the results that are generated
        // In this case we want the events sored by their timeStamps.
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.location);
        
        // Create the Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Return the fetched results controller. It will be the value of the lazy variable
        return fetchedResultsController
    } ()
}

extension GalleryViewController: UICollectionViewDataSource {
    
    // MARK: - Collection View Data Source
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        cell.setImage(nil)
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if let image = photo.image {
            cell.setImage(image)
        } else {
            setState(.Loading)
            let client = FlickrClient.sharedInstance()
            let task = client.downloadImage(photo) { success, errorString in
                self.saveContext()
            }
            
            //This is the custom property on this cell. See TaskCancelingTableViewCell.swift for details.
            cell.taskToCancelifCellIsReused = task
        }
        
        return cell
    }
}

extension GalleryViewController: UICollectionViewDelegate {
    
    // MARK: - Collection View Delegate
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        if collectionView.cellForItemAtIndexPath(indexPath)?.backgroundView != nil {
            return true
        } else {
            return false
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        setState(.DeletionMode)
        collectionView.cellForItemAtIndexPath(indexPath)?.backgroundView?.alpha = 0.5
    }
    
    func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        setState(.ViewMode)
        collectionView.cellForItemAtIndexPath(indexPath)?.backgroundView?.alpha = 1
    }
}

extension GalleryViewController: UICollectionViewDelegateFlowLayout {
    
    // MARK: - Collection View Delegate FlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let dimension: CGFloat = floor((CGRectGetWidth(view.bounds) - 4 * space) / 3)
        return CGSize(width: dimension, height: dimension)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return space
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return space
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: space, left: space, bottom: space, right: space)
    }
}

extension GalleryViewController: NSFetchedResultsControllerDelegate {
    
    struct MovedIndexPath {
        static let From = "from"
        static let To = "to"
    }
    
    // MARK: - Fetched Results Controller Delegate
    // Solution found here: https://gist.github.com/lukasreichart/0ce6b782a5428bd17904
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print("controllerWillChangeContent")
        shouldReloadCollectionView = false
        
        self.deletedIndexPaths.removeAll()
        self.newIndexPaths.removeAll()
        self.movedIndexPaths.removeAll()
        self.updatedIndexPaths.removeAll()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            if collectionView.numberOfItemsInSection(newIndexPath!.section) == 0 {
                shouldReloadCollectionView = true
            } else {
                newIndexPaths.append(newIndexPath!)
            }
        case .Update:
            // Exisiting data that are fetched when the controller is initialised are considered as updates but they do not exist yet in the collection view, therefore the collection view should be reloaded
            updatedIndexPaths.append(indexPath!)
        case .Delete:
            if fetchedResultsController.sections![indexPath!.section].numberOfObjects == 0 {
                shouldReloadCollectionView = true
            } else {
                deletedIndexPaths.append(indexPath!)
            }
        case .Move:
            movedIndexPaths.append([MovedIndexPath.From : indexPath!, MovedIndexPath.To : newIndexPath!])
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        if shouldReloadCollectionView {
            print("controllerDidChangeContent to reload data")
            dispatch_async(dispatch_get_main_queue()) {
                self.collectionView.reloadData() {
                    if (self.state == .Loading && controller.fetchedObjects!.count != 0) || self.state == .Deleting {
                        print("finish releasd data")
                        self.setState(.ViewMode)
                    }
                }
            }
        } else {
            print("controllerDidChangeContent to performBatchUpdates")
            
                self.collectionView.performBatchUpdates({
                    self.collectionView.deleteItemsAtIndexPaths(self.deletedIndexPaths)
                    self.collectionView.reloadItemsAtIndexPaths(self.updatedIndexPaths)
                    self.collectionView.insertItemsAtIndexPaths(self.newIndexPaths)
                    for i in self.movedIndexPaths {
                        self.collectionView.moveItemAtIndexPath(i[MovedIndexPath.From]!, toIndexPath: i[MovedIndexPath.To]!)
                    }
                }, completion: { success in
                    dispatch_async(dispatch_get_main_queue()) {
                        if (self.state == .Loading && controller.fetchedObjects!.count != 0) || self.state == .Deleting {
                            print("finish performBatchUpdates")
                            self.setState(.ViewMode)
                        }
                    }
                })
            }
        
    }
}

extension GalleryViewController {
    
    // MARK: - Enum
    
    enum State {
        case ViewMode
        case Loading
        case DeletionMode
        case Deleting
    }
}

extension UICollectionView {
    func reloadData(completion: ()->()) {
        UIView.animateWithDuration(0, animations: { self.reloadData() })
        { _ in completion() }
    }
}