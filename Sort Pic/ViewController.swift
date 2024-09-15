// © 2024 Suraj Van Verma. All rights reserved.
// Created on September 15, 2024, in Montreal, QC.

import AVFoundation
import Photos
import UIKit

class ViewController: UIViewController {

  // Properties to manage photo assets, current index, and UI components
  var photoAssets: PHFetchResult<PHAsset>?
  var currentIndex = 0
  var imageView: UIImageView!
  var categorySegmentedControl: UISegmentedControl!
  var player: AVPlayer?
  var playerLayer: AVPlayerLayer?
  var noPhotosLabel: UILabel!

  private let imageManager = PHCachingImageManager()

  // Setup media view for displaying images and videos
  func setupMediaView() {
    // Remove previous playerLayer if it exists
    playerLayer?.removeFromSuperlayer()

    // Setup imageView for displaying images
    imageView = UIImageView(frame: view.bounds.insetBy(dx: 20, dy: 100))  // Add margin
    imageView.contentMode = .scaleAspectFit
    imageView.layer.cornerRadius = 20
    imageView.clipsToBounds = true
    view.addSubview(imageView)

    // Setup playerLayer for video playback
    playerLayer = AVPlayerLayer(player: player)
    playerLayer?.videoGravity = .resizeAspect

    // Center playerLayer
    if let playerLayer = playerLayer {
      playerLayer.frame = view.bounds
      view.layer.addSublayer(playerLayer)
    }
  }

  // Setup label to display when no photos are available
  func setupNoPhotosLabel() {
    noPhotosLabel = UILabel(
      frame: CGRect(x: 0, y: (view.bounds.height / 2) - 20, width: view.bounds.width, height: 40))
    noPhotosLabel.text = "No Photos Available"
    noPhotosLabel.textAlignment = .center
    noPhotosLabel.font = UIFont.systemFont(ofSize: 18)
    noPhotosLabel.textColor = .gray
    noPhotosLabel.isHidden = true
    view.addSubview(noPhotosLabel)
  }

  // Setup the ImageView to display photos
  func setupImageView() {
    imageView = UIImageView(frame: view.bounds.insetBy(dx: 20, dy: 100))  // Add margin
    imageView.contentMode = .scaleAspectFit
    imageView.layer.cornerRadius = 20  // Adjust the corner radius to your liking
    imageView.clipsToBounds = true
    view.addSubview(imageView)
  }

  // Setup the heading label for the app
  func setupHeading() {
    let headingLabel = UILabel()
    headingLabel.translatesAutoresizingMaskIntoConstraints = false
    headingLabel.text = "PicSort"
    headingLabel.textAlignment = .center
    headingLabel.font = UIFont.boldSystemFont(ofSize: 28)
    headingLabel.isUserInteractionEnabled = true  // Enable user interaction
    view.addSubview(headingLabel)

    // Constraints to position the heading label
    NSLayoutConstraint.activate([
      headingLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),  // Adjusted top constraint
      headingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      headingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      headingLabel.heightAnchor.constraint(equalToConstant: 40),
    ])

    // Add tap gesture recognizer
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(headingTapped))
    headingLabel.addGestureRecognizer(tapGesture)
  }

  // Handle tap on heading label
  @objc func headingTapped() {
    if let url = URL(string: "https://www.linkedin.com/in/bythebug") {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
  }

  // Setup the segmented control for category selection
  func setupCategorySelector() {
    let items = ["Today", "Yesterday", "Last Week", "All", "Screenshots", "Videos"]
    categorySegmentedControl = UISegmentedControl(items: items)
    categorySegmentedControl.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(categorySegmentedControl)

    // Add target for value changed event
    categorySegmentedControl.addTarget(self, action: #selector(categoryChanged), for: .valueChanged)

    // Constraints for the segmented control
    NSLayoutConstraint.activate([
      categorySegmentedControl.bottomAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),  // 10pt padding from bottom
      categorySegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
      categorySegmentedControl.trailingAnchor.constraint(
        equalTo: view.trailingAnchor, constant: -10),
      categorySegmentedControl.heightAnchor.constraint(equalToConstant: 30),
    ])
  }

  // Request permission to access the Photo Library
  func requestPhotoLibraryPermission() {
    PHPhotoLibrary.requestAuthorization { status in
      switch status {
      case .authorized:
        self.loadPhotos()
      case .denied, .restricted:
        print("Photo library access denied or restricted.")
      case .notDetermined:
        print("Photo library access not determined.")
      case .limited:
        print("Limited Case")
      @unknown default:
        fatalError("Unhandled authorization status.")
      }
    }
  }

  // Load photos based on the selected category
  func loadPhotos() {
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

    // Fetch assets based on the selected category
    switch categorySegmentedControl.selectedSegmentIndex {
    case 0:  // Today
      let startOfDay = Calendar.current.startOfDay(for: Date())
      let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
      fetchOptions.predicate = NSPredicate(
        format: "creationDate >= %@ AND creationDate < %@", startOfDay as NSDate, endOfDay as NSDate
      )
    case 1:  // Yesterday
      let startOfYesterday = Calendar.current.date(
        byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
      let endOfYesterday = Calendar.current.startOfDay(for: Date())
      fetchOptions.predicate = NSPredicate(
        format: "creationDate >= %@ AND creationDate < %@", startOfYesterday as NSDate,
        endOfYesterday as NSDate)
    case 2:  // Last Week
      let startOfWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
      let endOfYesterday = Calendar.current.date(
        byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
      fetchOptions.predicate = NSPredicate(
        format: "creationDate >= %@ AND creationDate < %@", startOfWeek as NSDate,
        endOfYesterday as NSDate)
    case 3:  // All
      fetchOptions.predicate = nil
    case 4:  // Screenshots
      fetchOptions.predicate = NSPredicate(
        format: "mediaSubtype == %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
    case 5:  // Videos
      fetchOptions.predicate = NSPredicate(
        format: "mediaType == %d", PHAssetMediaType.video.rawValue)
    default:
      fetchOptions.predicate = nil
    }

    // Fetch assets
    self.photoAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)

    if categorySegmentedControl.selectedSegmentIndex == 5 {
      // Fetch videos if "Videos" category is selected
      self.photoAssets = PHAsset.fetchAssets(with: .video, options: fetchOptions)
    }

    // Check and handle results
    if let assets = self.photoAssets, assets.count > 0 {
      DispatchQueue.main.async {
        self.noPhotosLabel.isHidden = true
        self.displayPhoto(at: self.currentIndex)
      }
    } else {
      DispatchQueue.main.async {
        self.noPhotosLabel.isHidden = false
        self.noPhotosLabel.text =
          self.categorySegmentedControl.selectedSegmentIndex == 0
          ? "No Photos Today" : "No Photos Available"
        self.imageView.image = nil
      }
    }
  }

  func displayPhoto(at index: Int) {
    guard let assets = self.photoAssets, index < assets.count else {
      self.imageView.image = nil
      self.noPhotosLabel.isHidden = false
      return
    }

    let asset = assets.object(at: index)

    if asset.mediaType == .video {
      let videoManager = PHImageManager.default()
      videoManager.requestAVAsset(forVideo: asset, options: nil) {
        [weak self] (avAsset, audioMix, info) in
        guard let self = self, let avAsset = avAsset else { return }
        DispatchQueue.main.async {
          self.player = AVPlayer(playerItem: AVPlayerItem(asset: avAsset))
          self.playerLayer?.player = self.player
          self.player?.play()
          self.playerLayer?.frame = self.view.bounds
          self.imageView.isHidden = true
        }
      }
    } else {
      let options = PHImageRequestOptions()
      options.isSynchronous = false  // Ensure it's asynchronous
      imageManager.requestImage(
        for: asset, targetSize: self.imageView.bounds.size, contentMode: .aspectFit,
        options: options
      ) { image, _ in
        DispatchQueue.main.async {
          self.imageView.image = image
          self.imageView.isHidden = false
          self.playerLayer?.player = nil
        }
      }
    }

    self.noPhotosLabel.isHidden = true
  }

  // Setup swipe gesture recognizers for navigation
  func setupSwipeGestures() {
    let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
    swipeRight.direction = .right
    view.addGestureRecognizer(swipeRight)

    let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
    swipeLeft.direction = .left
    view.addGestureRecognizer(swipeLeft)
  }

  // Handle swipe gestures (left: delete, right: keep)
  @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
    if gesture.direction == .right {
      nextPhoto()
    } else if gesture.direction == .left {
      deleteCurrentPhoto()
    }
  }

  // Load the next photo in the collection
  func nextPhoto() {
    guard let assets = self.photoAssets, assets.count > 0 else { return }
    if currentIndex < assets.count - 1 {
      currentIndex += 1
      displayPhoto(at: currentIndex)
    }
  }

  // Delete the current photo from the library
  func deleteCurrentPhoto() {
    guard let assets = self.photoAssets, assets.count > 0 else { return }
    let assetToDelete = assets.object(at: self.currentIndex)

    PHPhotoLibrary.shared().performChanges({
      PHAssetChangeRequest.deleteAssets([assetToDelete] as NSArray)
    }) { [weak self] success, error in
      guard let self = self else { return }

      if success {
        DispatchQueue.main.async {
          if let assets = self.photoAssets, assets.count > 0 {
            // Update index after deletion
            if self.currentIndex >= assets.count {
              self.currentIndex = assets.count - 1
            }
            self.loadPhotos()  // Reload the photos after deletion
          } else {
            // No photos left
            self.noPhotosLabel.isHidden = false
            self.imageView.image = nil
          }
        }
      } else if let error = error {
        print("Error deleting photo: \(error.localizedDescription)")
      }
    }
  }

  // Handle category selection changes
  @objc func categoryChanged() {
    self.currentIndex = 0  // Reset index to the first photo
    self.loadPhotos()  // Reload photos based on the selected category
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupHeading()
    setupMediaView()  // Ensure this sets up the media view correctly
    setupCategorySelector()
    setupNoPhotosLabel()
    requestPhotoLibraryPermission()
    setupSwipeGestures()
  }
}
