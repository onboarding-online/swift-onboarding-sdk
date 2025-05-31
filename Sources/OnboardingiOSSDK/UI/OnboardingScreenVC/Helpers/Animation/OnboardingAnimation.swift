//
//  OnboardingAnimation.swift
//  OnboardingOnline
//
//  Copyright 2023 Onboarding.online on 03.03.2023.
//

import UIKit

final class OnboardingAnimation {
    
    static let animationDuration: TimeInterval = 0.7
    private static let delay: TimeInterval = 0.1
    
    static func runAnimationOfType(_ animationType: AnimationType,
                                   in view: UIView,
                                   delay: TimeInterval = OnboardingAnimation.delay) {
        switch animationType {
        case .fade:
            runFadeAnimation(in: view, delay: delay)
        case .moveAndFade(let moveDirection):
            let moveOffset = moveOffsetForDirection(moveDirection)
            runMoveAnimation(in: view, moveOffset: moveOffset, delay: delay)
            runAnimationOfType(.fade, in: view, delay: delay)
        case .tableViewCells(let style):
            guard let tableView = view as? UICollectionView else { return }
            
            runFadeAnimation(in: view)
            tableView.reloadData()
            tableView.clipsToBounds = false
            
            DispatchQueue.main.async {
                let cells = tableView.visibleCells
                
                let indexes = cells.compactMap { cell in
                    return tableView.indexPath(for: cell)
                }

                let sortedIndexes = indexes.sorted { index1, index2 in
                    return index1.row < index2.row
                }
                
                let sortedCells = sortedIndexes.compactMap { index in
                    tableView.cellForItem(at: index)
                }
                                            
                for (i, cell) in sortedCells.enumerated() {
                    cell.clipsToBounds = false
                    cell.contentView.clipsToBounds = false
                    let delay = OnboardingAnimation.delay + (OnboardingAnimation.delay * CGFloat(i) * 2)
                    switch style {
                    case .fade:
                        runFadeAnimation(in: cell, delay: delay)
                    case .move:
                        let dx = UIScreen.main.bounds.width
                        runMoveAnimation(in: cell,
                                         moveOffset: .init(dx: dx),
                                         animationDuration: 1.2,
                                         delay: delay,
                                         style: .spring(dampingRatio: 0.6))
                    }
                }
            }
            
        case .expand:
            runExpandAnimation(in: view,
                               expandRatio: .init(x: 0.5,
                                                  y: 0.5),
                               animationDuration: 1.2,
                               delay: delay,
                               style: .spring(dampingRatio: 0.6))
        }
    }
    
    static func runAnimationOfType(_ animationType: AnimationType,
                                   in views: [UIView],
                                   delay: TimeInterval = OnboardingAnimation.delay) {
        views.forEach { view in
            runAnimationOfType(animationType, in: view, delay: delay)
        }
    }
    
}

// MARK: - Private methods
private extension OnboardingAnimation {
    
    static func runMoveAnimation(in view: UIView,
                                 moveOffset: MoveOffset,
                                 animationDuration: TimeInterval = OnboardingAnimation.animationDuration,
                                 delay: TimeInterval = OnboardingAnimation.delay,
                                 style: AnimationStyle = .linear) {
        let currentOrigin = view.frame.origin
        let offsetOrigin = CGPoint(x: currentOrigin.x + moveOffset.dx,
                                   y: currentOrigin.y + moveOffset.dy)
        
        view.frame.origin = offsetOrigin
        runUIAnimation(animationDuration: animationDuration,
                       delay: delay,
                       style: style,
                       animationBlock: {
            view.frame.origin = currentOrigin
        })
    }
    
    static func runFadeAnimation(in view: UIView,
                                 isFadeIn: Bool = false,
                                 animationDuration: TimeInterval = OnboardingAnimation.animationDuration,
                                 delay: TimeInterval = OnboardingAnimation.delay,
                                 style: AnimationStyle = .linear) {
        let fromValue: CGFloat = isFadeIn ? 1 : 0
        let toValue: CGFloat = isFadeIn ? 0 : 1
        view.alpha = fromValue
        runUIAnimation(animationDuration: animationDuration,
                       delay: delay,
                       style: style,
                       animationBlock: {
            view.alpha = toValue
        })
    }
    
    static func runExpandAnimation(in view: UIView,
                                   expandRatio: ExpandRation,
                                   animationDuration: TimeInterval = OnboardingAnimation.animationDuration,
                                   delay: TimeInterval = OnboardingAnimation.delay,
                                   style: AnimationStyle = .linear) {
        let identityTransform = view.transform
        let collapsedTransform = identityTransform.scaledBy(x: expandRatio.x,
                                                            y: expandRatio.y)
        view.transform = collapsedTransform
        runUIAnimation(animationDuration: animationDuration,
                       delay: delay,
                       style: style,
                       animationBlock: {
            view.transform = identityTransform
        })
    }
    
    static func runUIAnimation(animationDuration: TimeInterval = OnboardingAnimation.animationDuration,
                               delay: TimeInterval = OnboardingAnimation.delay,
                               style: AnimationStyle = .linear,
                               animationBlock: @escaping EmptyCallback,
                               completion: EmptyCallback? = nil) {
        switch style {
        case .linear:
            UIView.animate(withDuration: animationDuration, delay: delay, animations: animationBlock) { _ in
                completion?()
            }
        case .spring(let dampingRatio, let velocity):
            UIView.animate(withDuration: animationDuration,
                           delay: delay,
                           usingSpringWithDamping: dampingRatio,
                           initialSpringVelocity: velocity,
                           options: [],
                           animations: animationBlock,
                           completion: { _ in
                completion?()
            })
        }
    }
    
    static func moveOffsetForDirection(_ direction: AnimationType.MoveDirection) -> MoveOffset {
        let offsetValue: CGFloat = 10
        switch direction {
        case .fromTopToBottom:
            return .init(dy: -offsetValue)
        case .fromBottomToTop:
            return .init(dy: offsetValue)
        }
    }
    
}

extension OnboardingAnimation {
    
    struct MoveOffset {
        var dx: CGFloat = 0
        var dy: CGFloat = 0
    }
    
    struct ExpandRation {
        var x: CGFloat = 0
        var y: CGFloat = 0
    }
    
}

extension OnboardingAnimation {
    
    enum AnimationType {
        case fade
        case moveAndFade(direction: MoveDirection)
        case tableViewCells(style: TableViewAnimationStyle)
        case expand
        
        enum MoveDirection {
            case fromTopToBottom
            case fromBottomToTop
        }
        
        enum TableViewAnimationStyle {
            case fade, move
        }
    }
    
    enum AnimationStyle {
        case linear
        case spring(dampingRatio: CGFloat,
                    velocity: CGFloat = 0)
    }
    
}

extension UIImageView {
    
    func setImage(_ image: UIImage?, animated: Bool = true) {
        if animated {
            UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.image = image
            }, completion: nil)
        } else {
            self.image = image
        }
    }
    
}
