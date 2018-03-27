//
//  AnimatorManager.swift
//  Pay-n-ride
//
//  Created by Paweł Szudrowicz on 27.03.2018.
//  Copyright © 2018 Paweł Szudrowicz. All rights reserved.
//

import UIKit

class AnimatorManager {
    static func showMapView(view: UIView) -> UIViewPropertyAnimator {
        let constraint = view.constraints.filter { (constraint) -> Bool in
            return constraint.identifier == "topConstraint"
            }.first!
        let animatorUp = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.5) {
            constraint.constant = 20
            view.layoutIfNeeded()
        }
        
        animatorUp.addCompletion({ (position) in
            switch position {
            case .end:
                constraint.constant = 20
            case .start:
                constraint.constant = 400
            default: break
            }
        })
        return animatorUp
    }
    
    static func hideMapView(view: UIView) -> UIViewPropertyAnimator {
        let constraint = view.constraints.filter { (constraint) -> Bool in
            return constraint.identifier == "topConstraint"
            }.first!
        
        let animatorDown =  UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.5) {
            constraint.constant = 400
            view.layoutIfNeeded()
        }
        
        animatorDown.addCompletion({ (position) in
            switch position {
            case .end:
                constraint.constant = 400
            case .start:
                constraint.constant = 20
                
            default: break
            }
        })
        return animatorDown
    }
}
