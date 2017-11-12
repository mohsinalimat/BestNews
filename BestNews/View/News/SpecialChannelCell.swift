//
//  SpecialChannelCell.swift
//  BestNews
//
//  Created by Worthy on 2017/11/5.
//  Copyright © 2017年 wuxi. All rights reserved.
//

import UIKit
import Kingfisher

class SpecialChannelCell: UITableViewCell {

    @IBOutlet weak var coverImg: UIImageView!
    
    @IBOutlet weak var titleLb: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func updateCell(data: SpecialChannel) {
        let rc = ImageResource(downloadURL: URL(string: data.preimgpath)!)
        coverImg.kf.setImage(with: rc)
        titleLb.text = data.name
    }
    
}
