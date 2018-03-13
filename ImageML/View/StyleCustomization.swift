//
//  StyleCustomization.swift
//  ImageML
//
//  Created by Saif Khan on 3/12/18.
//  Copyright © 2018 SaifSide Inc. All rights reserved.
//

import UIKit

final class StyleCustomization {

    static let shared: StyleCustomization = StyleCustomization()
    private init(){}
    
    // Shadow and Corner Radius Helper Method
    func addShadowAndCornerRadius(selfView: UIView,shadowColor: CGColor, shadowRadius: CGFloat, shadowOpacity: Float, cornerRadius: CGFloat) {
        
        // Shadow Customization
        selfView.layer.shadowColor = shadowColor
        
        // Blur Shadow (More Blur - Higher Number)
        selfView.layer.shadowRadius = shadowRadius
        
        // Shadow Opacity
        selfView.layer.shadowOpacity = shadowOpacity
        
        // Add Corner Radius
        selfView.layer.cornerRadius = cornerRadius
    }
}
