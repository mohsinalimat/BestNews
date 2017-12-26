//
//  ProfileCenterController.swift
//  BestNews
//
//  Created by Worthy on 2017/10/26.
//  Copyright © 2017年 wuxi. All rights reserved.
//

import UIKit
import Kingfisher
import ImagePicker

class ProfileCenterController: BaseViewController, ImagePickerDelegate, UITextFieldDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var avatarImg: UIImageView!
    
    @IBOutlet weak var nicknameTf: UITextField!
    
    @IBOutlet weak var descLb: UILabel!
    
    @IBOutlet weak var columnContainerView: UIView!
   
    @IBOutlet weak var phoneLb: UILabel!
    
    @IBOutlet weak var wechatLb: UILabel!
    
    @IBOutlet weak var weiboLb: UILabel!
    
    @IBOutlet weak var qqLb: UILabel!
    
    @IBOutlet weak var descView: UIView!
    
    @IBOutlet weak var accountView: UIView!
    
    @IBOutlet weak var accountTop: NSLayoutConstraint!
    
    var avatarUrl: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        self.showCustomTitle(title: "我的资料")
        
        updateUI()
    }

    func updateUI() {
        
        if let user = SessionManager.sharedInstance.userInfo {
            if let url = URL(string: user.headimg) {
                let rc = ImageResource(downloadURL: url)
                avatarImg.kf.setImage(with: rc)
            }
            nicknameTf.text = user.name
            descLb.text = user.intro
            
            if user.celebrityflag {
                accountTop.constant = descView.height+30
                descView.isHidden = false
            }
            else {
                accountTop.constant = 15
                descView.isHidden = true
            }
            if user.mobile.count > 0 && user.mobile != "<null>" {
                phoneLb.text = user.mobile
            }
            else {
                phoneLb.text = "未绑定"
            }
            if user.wxinfo.count > 0 && user.wxinfo != "<null>" {
                wechatLb.text = user.wxinfo
            }
            else {
                wechatLb.text = "未绑定"
            }
            if user.wbinfo.count > 0 && user.wbinfo != "<null>" {
                weiboLb.text = user.wbinfo
            }
            else {
                weiboLb.text = "未绑定"
            }
            if user.qqinfo.count > 0 && user.qqinfo != "<null>" {
                qqLb.text = user.qqinfo
            }
            else {
                qqLb.text = "未绑定"
            }
            nicknameTf.delegate = self
        }
        
        let save = UIBarButtonItem(title: "保存", style: UIBarButtonItemStyle.plain, target: self, action: #selector(handleTapSave(_:)))
        navigationItem.rightBarButtonItem = save
        
    }
    

    //MARK: - actions
    
    func handleTapSave(_ : Any) {
        let nickname = nicknameTf.text
        if nickname != SessionManager.sharedInstance.userInfo?.name {
            view.tag = 2
        }
        if nickname?.count == 0 || view.tag == 0 {
            return
        }
        var params = ["name": nickname!]
        if avatarUrl != nil {
            params["headimg"] = avatarUrl!
        }
        SessionManager.sharedInstance.userInfo?.updateUserInfoWithParams(params: params, result: { (success, msg) in
            if !success {
                BLHUDBarManager.showError(msg: msg)
            }
            else {
                DispatchQueue.main.async {
                   BLHUDBarManager.showSuccess(msg: "更新成功!", seconds: 1)
                    self.navigationController?.popViewController(animated: true)
                }
            }
        })
    }
    
    @IBAction func handleTapAvatar(_ sender: Any) {
        let picker = ImagePickerController()
        picker.imageLimit = 1
        picker.delegate = self
        self.present(picker, animated: true) {
            
        }
    }
    
    @IBAction func handleTapPhone(_ sender: Any) {
        
    }
    
    @IBAction func handleTapWechat(_ sender: Any) {
        
    }
    
    @IBAction func handleTapWeibo(_ sender: Any) {
        
    }
    
    @IBAction func handleTapQQ(_ sender: Any) {
        
    }
    
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        imagePicker.dismiss(animated: true) {
            [weak self] in
            self?.avatarImg.image = images.first
            
            //上传图片
            let hud = self?.pleaseWait()
            let img = images.first?.imageWithMaxSize(maxSize: 1920)
            let data = UIImageJPEGRepresentation(img!, 0.8)
            APIManager.shareInstance.uploadFile(data: data!, result: { (JSON, code, msg) in
                hud?.hide()
                if code == 0 {
                    hud?.hide()
                    self?.view.tag = 1
                    SessionManager.sharedInstance.userInfo?.headimg = JSON!["data"]["url"].stringValue
                    let url = JSON!["data"]["url"].stringValue
                    self?.avatarUrl = url
                    
                }
                else {
                    hud?.noticeError(msg)
                }
            })
        }
    }
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        imagePicker.dismiss(animated: true, completion: nil)
    }

}
