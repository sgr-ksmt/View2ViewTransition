//
//  DismissInteractiveTransition.swift
//  CustomTransition
//
//  Created by naru on 2016/08/29.
//  Copyright © 2016年 naru. All rights reserved.
//

import UIKit

open class DismissInteractiveTransition: UIPercentDrivenInteractiveTransition {
    
    // MARK: Elements
    
    open var interactionInProgress: Bool = false
    
    open weak var transitionController: TransitionController!
    
    open weak var animationController: DismissAnimationController!
    
    open var initialPanPoint: CGPoint! = CGPoint.zero
    
    fileprivate(set) var transitionContext: UIViewControllerContextTransitioning!
    
    // MARK: Gesture
    
    open override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        super.startInteractiveTransition(transitionContext)
    }
    
    open func handlePanGesture(_ panGestureRecognizer: UIPanGestureRecognizer) {
        
        if panGestureRecognizer.state == .began {
            
            self.interactionInProgress = true
            self.initialPanPoint = panGestureRecognizer.location(in: panGestureRecognizer.view)
            
            switch self.transitionController.type {
            case .presenting:
                self.transitionController.presentedViewController?.dismiss(animated: true, completion: nil)
            case .pushing:
                _ = self.transitionController.presentedViewController?.navigationController!.popViewController(animated: true)
            }
            
            return
        }
        
        guard let animationController = animationController,
            let presentingViewController = transitionController.presentingViewController,
            let destinationTransitionView = animationController.destinationTransitionView,
            let initialTransitionView = animationController.initialTransitionView else
        {
            return
        }
        // Get Progress
        let range: Float = Float(UIScreen.main.bounds.size.width)
        let location: CGPoint = panGestureRecognizer.location(in: panGestureRecognizer.view)
        let distance: Float = sqrt(powf(Float(self.initialPanPoint.x - location.x), 2.0) + powf(Float(self.initialPanPoint.y - location.y), 2.0))
        let progress: CGFloat = CGFloat(fminf(fmaxf((distance / range), 0.0), 1.0))
        
        // Get Transration
        let translation: CGPoint = panGestureRecognizer.translation(in: panGestureRecognizer.view)
        
        switch panGestureRecognizer.state {
            
        case .changed:
            
            update(progress)
            
            destinationTransitionView.alpha = 1.0
            initialTransitionView.alpha = 0.0
            
            // Affine Transform
            let scale: CGFloat = (1000.0 - CGFloat(distance))/1000.0
            var transform = CGAffineTransform.identity
            transform = transform.scaledBy(x: scale, y: scale)
            transform = transform.translatedBy(x: translation.x/scale, y: translation.y/scale)
            
            destinationTransitionView.transform = transform
            initialTransitionView.transform = transform
            
        case .cancelled:
            
            self.interactionInProgress = false
            self.transitionContext.cancelInteractiveTransition()
            
        case .ended:
            
            self.interactionInProgress = false
            panGestureRecognizer.setTranslation(CGPoint.zero, in: panGestureRecognizer.view)
            
            if progress < 0.5 {
                
                cancel()
                
                let duration: Double = Double(self.duration)*Double(progress)
                UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: UIViewAnimationOptions(), animations: {
                    
                    destinationTransitionView.frame = self.animationController.destinationFrame
                    initialTransitionView.frame = self.animationController.destinationFrame
                    
                }, completion: { _ in
                        
                    // Cancel Transition
                    destinationTransitionView.removeFromSuperview()
                    initialTransitionView.removeFromSuperview()
                   
                    self.animationController.destinationView.isHidden = false
                    self.animationController.initialView.isHidden = false
//                    self.transitionController.presentingViewController.view.removeFromSuperview()
                    
                    self.transitionContext.completeTransition(false)
                })
                
            } else {
                
                finish()
                presentingViewController.view.isUserInteractionEnabled = false
                
                let duration: Double = animationController.transitionDuration
                UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.0, options: UIViewAnimationOptions(), animations: {
                    
                    destinationTransitionView.alpha = 0.0
                    initialTransitionView.alpha = 1.0

                    destinationTransitionView.frame = self.animationController.initialFrame
                    initialTransitionView.frame = self.animationController.initialFrame
                    
                }, completion: { _ in
                    
                    if self.transitionController.type == .pushing {
                            
                        destinationTransitionView.removeFromSuperview()
                        initialTransitionView.removeFromSuperview()
                            
                        self.animationController.initialView.isHidden = false
                        self.animationController.destinationView.isHidden = false
                    }
                    
                    presentingViewController.view.isUserInteractionEnabled = true
                    self.animationController.initialView.isHidden = false
                    self.transitionContext.completeTransition(true)
                })
            }
            
        default:
            break
        }
    }
}
