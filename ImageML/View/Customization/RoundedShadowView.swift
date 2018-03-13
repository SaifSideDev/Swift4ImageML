//
//  RoundedShadowView.swift
//  ImageML
//
//  Created by Saif Khan on 3/12/18.
//  Copyright © 2018 SaifSide Inc. All rights reserved.
//

import UIKit

class RoundedShadowView: UIView {

    override func awakeFromNib() {
        StyleCustomization.shared.addShadowAndCornerRadius(selfView: self, shadowColor: UIColor.darkGray.cgColor, shadowRadius: 16.0, shadowOpacity: 0.7, cornerRadius: 10.0)
    }
}
