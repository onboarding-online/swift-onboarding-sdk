
//OnboardingService.shared.permissionRequestCallback = {[weak self](screen, permissionType) in
//    self?.askPermissionsFor(permissionType: permissionType, completion: { granted in
//        print(granted)
//    })
//}

//import UserNotifications
//import AppTrackingTransparency

//fileprivate extension YourController {
//
//    func askPermissionsFor(permissionType: ScreenPermissionType, completion: @escaping BoolCallback) {
//        switch permissionType {
//        case .notifications:
//            checkNotificationsPermissions(options: [.badge, .sound, .alert],
//                                          completion: completion)
//        case .ads:
//            if #available(iOS 14, *) {
//                checkAdsPermissions(completion: completion)
//            }
//        }
//    }
//
//    func checkNotificationsPermissions(options: UNAuthorizationOptions, completion: @escaping BoolCallback) {
//        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
//            let authorizationStatus = settings.authorizationStatus
//            switch authorizationStatus {
//            case .authorized:
//                completion(true)
//            case .denied:
//                completion(false)
//            default:
//                UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: { (granted, _) in
//                    completion(granted)
//                })
//            }
//        }
//    }
//
//    func checkAdsPermissions(completion: @escaping BoolCallback) {
//        if #available(iOS 14, *) {
//            // Display permission to track
//            ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
//                switch status {
//                case .notDetermined:
//                    completion(false)
//                case .restricted:
//                    completion(false)
//                case .denied:
//                    completion(false)
//                case .authorized:
//                    completion(true)
//                default:
//                    completion(false)
//                }
//            })
//        }
//    }
//
//}




////
////  PermissionsService.swift
////  OnboardingOnline
////
////  Copyright 2023 Onboarding.online on 21/02/2019.
////  OnboardingOnline. All rights reserved.
////
//
//import UIKit
////import AVKit
////import CoreMotion
////import Photos
//import UserNotifications
////import EventKit
//import ScreensGraph
//import AppTrackingTransparency
//
//public enum PermissionType {
//    case camera
//    case coreMotion
//    case photoLibrary
//    case notifications
//    case location
//    case locationService
//    case microphone
//    case calendar
//}
//
//typealias PermissionsServiceCallback = (_ granted: Bool) -> ()
//
//// MARK: - PermissionsServiceHolderProtocol
//protocol PermissionsServiceHolderProtocol {
//    var permissionsService: PermissionsServiceProtocol { get }
//}
//
//// MARK: - PermissionsServiceProtocol
//protocol PermissionsServiceProtocol {
////    func checkCameraPermissions(in viewController: UIViewController, completion: @escaping PermissionsServiceCallback)
////    func checkCoreMotionPermissions(in viewController: UIViewController, completion: @escaping PermissionsServiceCallback)
////    func checkPhotoLibraryPermissions(in viewController: UIViewController, completion: @escaping PermissionsServiceCallback)
//    func checkNotificationsPermissions(in viewController: UIViewController?, options: UNAuthorizationOptions, completion: @escaping PermissionsServiceCallback)
////    func checkLocationPermissions(in viewController: UIViewController, shouldShowSettingsAlert: Bool, completion: @escaping PermissionsServiceCallback)
////    func checkMicrophonePermissions(in viewController: UIViewController, shouldShowSettingsAlert: Bool, completion: @escaping PermissionsServiceCallback)
////    func checkCalendarPermissions(in viewController: UIViewController, completion: @escaping PermissionsServiceCallback)
//    func isPermissionsGrantedFor(permissionType: ScreenPermissionType) -> Bool?
//
//}
//
//// MARK: - PermissionsService
//class PermissionsService: NSObject {
//
//    static let shared = PermissionsService()
//
//    fileprivate var requestingViewController: UIViewController?
//    fileprivate var requestingCallback: PermissionsServiceCallback?
//    fileprivate var requestingShouldShowSettingsAlert = true
////    fileprivate let clLocationManager = CLLocationManager()
//
//    private override init() { }
//}
//
//// MARK: - Open methods
//extension PermissionsService {
//
//    func askPermissionsFor(permissionType: ScreenPermissionType,
//                           in viewController: UIViewController,
//                           completion: @escaping PermissionsServiceCallback) {
//        switch permissionType {
//        case .notifications:
//            checkNotificationsPermissions(in: viewController,
//                                          options: [.badge, .sound, .alert],
//                                          completion: completion)
//        case .ads:
//            if #available(iOS 14, *) {
//                // Display permission to track
//                ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
//                    switch status {
//                    case .notDetermined:
//                        completion(false)
//                    case .restricted:
//                        completion(false)
//                    case .denied:
//                        completion(false)
//                    case .authorized:
//                        completion(true)
//                    default:
//                        completion(false)
//                    }
//                })
//            }
//        }
////        case .camera:
////            checkCameraPermissions(in: viewController,
////                                   completion: completion)
////        case .coremotion:
////            checkCoreMotionPermissions(in: viewController,
////                                       completion: completion)
////        case .photolibrary:
////            checkPhotoLibraryPermissions(in: viewController,
////                                         completion: completion)
//
////        case .location, .locationservice:
////            checkLocationPermissions(in: viewController,
////                                     shouldShowSettingsAlert: true,
////                                     completion: completion)
////        case .microphone:
////            checkMicrophonePermissions(in: viewController,
////                                       shouldShowSettingsAlert: true,
////                                       completion: completion)
////        case .calendar:
////            checkCalendarPermissions(in: viewController,
////                                     completion: completion)
//    }
//
//    func isPermissionsGrantedFor(permissionType: ScreenPermissionType) -> Bool? {
//        switch permissionType {
//        case .notifications:
//            return true
//        case .ads:
//            return true
//        }
//    }
////        case .camera:
////            let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
////            switch authorizationStatus {
////            case .authorized:
////                return true
////            case .denied:
////                return false
////            default:
////                return nil
////            }
////        case .coremotion:
////            let authorizationStatus = CMPedometer.authorizationStatus()
////            switch authorizationStatus {
////            case .authorized:
////                return true
////            case .denied:
////                return false
////            default:
////                return nil
////            }
////        case .photolibrary:
////            let authorizationStatus = PHPhotoLibrary.authorizationStatus()
////            switch authorizationStatus {
////            case .authorized:
////                return true
////            case .denied:
////                return false
////            default:
////                return nil
////            }
//
////            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
////                let authorizationStatus = settings.authorizationStatus
////                switch authorizationStatus {
////                case .authorized:
////                    return false
////                case .denied:
////                    return false
////                default:
////                    return true
////                }
////            }
////        case .location, .locationservice:
////            if CLLocationManager.locationServicesEnabled() {
////                switch CLLocationManager.authorizationStatus() {
////                case .notDetermined:
////                    return false
////                case .restricted, .denied:
////                    return false
////                case .authorizedAlways, .authorizedWhenInUse:
////                    return true
////                @unknown default:
////                    return nil
////                }
////            } else {
////                return true
////            }
////        case .microphone:
////            switch AVAudioSession.sharedInstance().recordPermission {
////            case AVAudioSession.RecordPermission.granted:
////                return true
////            case AVAudioSession.RecordPermission.denied:
////                return false
////            case AVAudioSession.RecordPermission.undetermined:
////                return false
////            @unknown default:
////                return nil
////            }
////        case .calendar:
////            let store = EKEventStore()
////            let authorizationStatus = EKEventStore.authorizationStatus(for: .event)
////            switch authorizationStatus {
////            case .authorized:
////                return true
////            case .denied:
////                return false
////            default:
////                return nil
////            }
////        }
//
//}
//
//// MARK: - PermissionsServiceProtocol
//extension PermissionsService: PermissionsServiceProtocol {
//
////    func checkCameraPermissions(in viewController: UIViewController, completion: @escaping PermissionsServiceCallback) {
////        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
////        switch authorizationStatus {
////        case .authorized:
////            checkGrantedStatusAndReturn(granted: true, in: viewController, forType: .camera, completion: completion)
////        case .denied:
////            checkGrantedStatusAndReturn(granted: false, in: viewController, forType: .camera, completion: completion)
////        default:
////            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [unowned self] (granted: Bool) in
////                self.checkGrantedStatusAndReturn(granted: granted, in: viewController, forType: .camera, completion: completion)
////            })
////        }
////    }
//
////    func checkCalendarPermissions(in viewController: UIViewController, completion: @escaping PermissionsServiceCallback) {
////        let store = EKEventStore()
////        let authorizationStatus = EKEventStore.authorizationStatus(for: .event)
////        switch authorizationStatus {
////        case .authorized:
////            checkGrantedStatusAndReturn(granted: true, in: viewController, forType: .calendar, completion: completion)
////        case .denied:
////            checkGrantedStatusAndReturn(granted: false, in: viewController, forType: .calendar, completion: completion)
////        default:
////            store.requestAccess(to: .event) { [unowned self, weak viewController] granted, error in
////                mainQueue.async {
////                    guard let viewController = viewController else { return }
////
////                    self.checkGrantedStatusAndReturn(granted: granted, in: viewController, forType: .calendar, completion: completion)
////                }
////            }
////        }
////    }
//
////    func checkCoreMotionPermissions(in viewController: UIViewController, completion: @escaping PermissionsServiceCallback) {
////        let authorizationStatus = CMPedometer.authorizationStatus()
////        switch authorizationStatus {
////        case .authorized:
////            checkGrantedStatusAndReturn(granted: true, in: viewController, forType: .coreMotion, completion: completion)
////        case .denied:
////            checkGrantedStatusAndReturn(granted: false, in: viewController, forType: .coreMotion, completion: completion)
////        default:
////            // FIXME: if Apple implements 'requestAuthorization' for core motion, implement it below
////            // As temp fix return true for not preventing Core Motion usage
////            checkGrantedStatusAndReturn(granted: true, in: viewController, forType: .coreMotion, completion: completion)
////        }
////    }
//
////    func checkPhotoLibraryPermissions(in viewController: UIViewController, completion: @escaping PermissionsServiceCallback) {
////        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
////        switch authorizationStatus {
////        case .authorized:
////            checkGrantedStatusAndReturn(granted: true, in: viewController, forType: .photoLibrary, completion: completion)
////        case .denied:
////            checkGrantedStatusAndReturn(granted: false, in: viewController, forType: .photoLibrary, completion: completion)
////        default:
////            PHPhotoLibrary.requestAuthorization { [unowned self] (status) in
////                self.checkGrantedStatusAndReturn(granted: status == .authorized, in: viewController, forType: .photoLibrary, completion: completion)
////            }
////        }
////    }
//
//    func checkNotificationsPermissions(in viewController: UIViewController?, options: UNAuthorizationOptions, completion: @escaping PermissionsServiceCallback) {
//        func checkGrantedStatusAndReturnIfHasViewController(granted: Bool) {
//            if let viewController = viewController {
//                checkGrantedStatusAndReturn(granted: granted, in: viewController, forType: .notifications, completion: completion)
//            }
//        }
//
//        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
//            let authorizationStatus = settings.authorizationStatus
//            switch authorizationStatus {
//            case .authorized:
//                checkGrantedStatusAndReturnIfHasViewController(granted: true)
//            case .denied:
//                checkGrantedStatusAndReturnIfHasViewController(granted: false)
//            default:
//                UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: { (granted, _) in
//                    checkGrantedStatusAndReturnIfHasViewController(granted: granted)
//                })
//            }
//        }
//    }
//
////    func checkLocationPermissions(in viewController: UIViewController, shouldShowSettingsAlert: Bool, completion: @escaping PermissionsServiceCallback) {
////        if CLLocationManager.locationServicesEnabled() {
////            switch CLLocationManager.authorizationStatus() {
////            case .notDetermined:
////                self.requestingViewController = viewController
////                self.requestingCallback = completion
////                self.requestingShouldShowSettingsAlert = shouldShowSettingsAlert
////                clLocationManager.delegate = self
////                clLocationManager.requestWhenInUseAuthorization()
////            case .restricted, .denied:
////                self.checkGrantedStatusAndReturn(granted: false, in: viewController, forType: .location, shouldShowSettingsAlert: shouldShowSettingsAlert, completion: completion)
////            case .authorizedAlways, .authorizedWhenInUse:
////                self.checkGrantedStatusAndReturn(granted: true, in: viewController, forType: .location, shouldShowSettingsAlert: shouldShowSettingsAlert, completion: completion)
////            @unknown default:
////                completion(false)
////            }
////        } else {
////            self.checkGrantedStatusAndReturn(granted: false, in: viewController, forType: .locationService, shouldShowSettingsAlert: shouldShowSettingsAlert, completion: completion)
////        }
////    }
//
////    func checkMicrophonePermissions(in viewController: UIViewController, shouldShowSettingsAlert: Bool, completion: @escaping PermissionsServiceCallback) {
////        switch AVAudioSession.sharedInstance().recordPermission {
////        case AVAudioSession.RecordPermission.granted:
////            checkGrantedStatusAndReturn(granted: true, in: viewController, forType: .microphone, shouldShowSettingsAlert: shouldShowSettingsAlert, completion: completion)
////        case AVAudioSession.RecordPermission.denied:
////            checkGrantedStatusAndReturn(granted: false, in: viewController, forType: .microphone, shouldShowSettingsAlert: shouldShowSettingsAlert, completion: completion)
////        case AVAudioSession.RecordPermission.undetermined:
////            AVAudioSession.sharedInstance().requestRecordPermission({ [unowned self] (granted) in
////                self.checkGrantedStatusAndReturn(granted: granted, in: viewController, forType: .microphone, shouldShowSettingsAlert: shouldShowSettingsAlert, completion: completion)
////            })
////        @unknown default:
////            completion(false)
////        }
////    }
//}
//
////// MARK: - CLLocationManagerDelegate
////extension PermissionsService: CLLocationManagerDelegate {
////
////    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
////        if let viewController = self.requestingViewController, let completion = self.requestingCallback {
////            self.checkLocationPermissions(in: viewController, shouldShowSettingsAlert: requestingShouldShowSettingsAlert, completion: completion)
////            self.requestingCallback = nil
////            self.requestingViewController = nil
////        }
////    }
////
////}
//
//// MARK: - Private methods
//fileprivate extension PermissionsService {
//
//    func checkGrantedStatusAndReturn(granted: Bool, in viewController: UIViewController, forType type: PermissionType, shouldShowSettingsAlert: Bool = true, completion: @escaping PermissionsServiceCallback) {
//        completion(granted)
//    }
//
//}
