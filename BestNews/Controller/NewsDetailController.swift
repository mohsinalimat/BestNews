//
//  NewsDetailController.swift
//  BestNews
//
//  Created by Worthy on 2017/10/3.
//  Copyright © 2017年 wuxi. All rights reserved.
//

import UIKit
import WebKit
import Presentr
import Kingfisher

class NewsDetailController: BaseViewController, UITableViewDelegate, UITableViewDataSource, CommentBarDelegate, WKNavigationDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var titleLb: UILabel!
    
    @IBOutlet weak var avtarBtn: UIButton!
    
    @IBOutlet weak var authorNameLb: UILabel!
    
    @IBOutlet weak var subscriptBtn: SubscribeButton!
    
    @IBOutlet weak var dateLb: UILabel!
    
    @IBOutlet weak var webParentView: UIView!
    
    @IBOutlet weak var webParentHeight: NSLayoutConstraint!
    @IBOutlet weak var rewardView: UIView!
    
    @IBOutlet weak var rewardBtn: UIButton!
    
    @IBOutlet weak var rewardViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    
    
    ///是否订阅作者 (需要查阅)
    var authorSubscribe = false
    
    var articleId: String = ""
    var article: HomeNewsDetail?
    var recommendArticleList: HomeArticleList?
    
    var commentBar = NewsCommentBar()
    
    var commentList: CommentList?
    
    lazy var webView: WKWebView = {
       let config = WKWebViewConfiguration()
        config.preferences = WKPreferences()
        config.preferences.minimumFontSize = 42
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        let web = WKWebView(frame: CGRect.init(x: 20, y: 0, width: screenWidth - 20, height: 100), configuration: config)
        web.scrollView.isScrollEnabled = false
        web.autoresizingMask = .flexibleHeight
        web.navigationDelegate = self
        self.webParentView.addSubview(web)
        return web
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        commentBar.frame = CGRect(x: 0, y: screenHeight-49, width: screenWidth, height: 49)
        commentBar.delegate = self
        view.addSubview(commentBar)
        let nib = UINib(nibName: "SinglePhotoNewsCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "SinglePhotoNewsCell")
        let nib1 = UINib(nibName: "NoPhotoNewsCell", bundle: nil)
        tableView.register(nib1, forCellReuseIdentifier: "NoPhotoNewsCell")
        
        tableView.sectionFooterHeight = 0.1
        tableView.sectionHeaderHeight = 0.1
//        tableView.rowHeight = 108
        tableView.estimatedRowHeight = 220
        tableView.rowHeight = UITableViewAutomaticDimension
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        self.automaticallyAdjustsScrollViewInsets = false
        
        commentBar.articleId = articleId
        self.loadNewsDetail()
        self.loadRecommendArticleList()
        self.loadCommentList()
        
    }
    
    //MARK: - tableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recommendArticleList?.list.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let article = recommendArticleList!.list[indexPath.row]
        var identifier = "SinglePhotoNewsCell"
        if article.preimglist.count == 0 {
            identifier = "NoPhotoNewsCell"
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! BaseNewsCell
        cell.updateCell(article: article)
        tableViewHeight.constant = tableView.contentSize.height
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let article = recommendArticleList!.list[indexPath.row]
        let vc = NewsDetailController(nibName: "NewsDetailController", bundle: nil)
        vc.articleId = article.id
        navigationController?.pushViewController(vc, animated: true)
    }

    //MARK: - actions
    
    @IBAction func handleTapSubscriptBtn(_ sender: UIButton) {
        if article != nil {
            if article!.subseribe == 0 {
                subscriptBtn.switchStateSub(true)
                article?.subseribe = 1
                APIRequest.subscriptChannelAPI(id: article!.userid, type: "user", result: { [weak self](success) in
                    if !success {
                        self?.article?.subseribe = 0
                        self?.subscriptBtn.switchStateSub(false)
                    }
                })
            }
            else {
                subscriptBtn.switchStateSub(false)
                article?.subseribe = 0
                APIRequest.cancelSubscriptChannelAPI(id: article!.userid, type: "user", result: { [weak self](success) in
                    if !success {
                        self?.article?.subseribe = 1
                        self?.subscriptBtn.switchStateSub(true)
                    }
                })
            }
        }
    }
    
    @IBAction func handleTapRewardBtn(_ sender: UIButton) {
        
    }
 
    //MARK: - commentBarDelegate
    
    func tapPostHandler() {
        let content = commentBar.textField.text
        if content?.count == 0 {
            return
        }
        APIRequest.commentAPI(articleId: articleId, commentId: nil, content: content!) { [weak self](JSON) in
            self?.loadCommentList()
            self?.commentBar.textField.text = ""
            self?.commentBar.switchToEditMode(edit: false)
        }
    }
    
    func tapReportHandler() {
        
    }
    
    func postSuccessHandler() {
        
    }
    
    func tapCommentHandler() {
        let vc = CommentListController()
        vc.commentList = commentList
        vc.articleId = articleId
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tapCollectionHandler() {
        if article?.collect == 0 {
            APIRequest.collectAPI(id: article!.id, type: "article", result: {[weak self] (success) in
                if success {
                    self?.article?.collect = 1
                    self?.commentBar.collect(true)
                }
                else {
                    self?.article?.collect = 0
                    self?.commentBar.collect(false)
                }
            })
        }
        else {
            APIRequest.cancelCollectAPI(id: article!.id, type: "article", result: { [weak self] (success) in
                if success {
                    self?.article?.collect = 0
                    self?.commentBar.collect(false)
                }
                else {
                    self?.article?.collect = 1
                    self?.commentBar.collect(true)
                }
            })
        }
    }
    
    func tapRepostHandler() {
        let vc = BaseShareViewController(nibName: "BaseShareViewController", bundle: nil)
        let share = ShareModel()
        share.title = article!.title
        share.msg = ""
        share.thumb = article!.headimg
        vc.share = share
        presentr.viewControllerForContext = self
        presentr.shouldIgnoreTapOutsideContext = false
        presentr.dismissOnTap = true
        customPresentViewController(presentr, viewController: vc, animated: true) {
            
        }
        
    }
    
    
    //MARK: - wkNavigation
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("开始加载...\(webView.scrollView.contentSize.height)")
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("收到重定向...")
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("content 处理完毕...\(webView.scrollView.contentSize.height)")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("数据下载失败...")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
//        webView.sizeToFit()
        print("高度...> \(webView.scrollView.contentSize.height)")
        webView.evaluateJavaScript("document.documentElement.scrollHeight;") { (data, error) in
            print("加载完毕...>\(data!)")
            self.webView.height = (data as! CGFloat)/2
            self.webParentHeight.constant = (data as! CGFloat)/2
        }
    }
    
}

/// load data
extension NewsDetailController {
    
    func loadNewsDetail() {
        APIRequest.newsDetailAPI(id: articleId) { [weak self](newsDetail) in
            self?.article = newsDetail as! HomeNewsDetail?
            self?.updateView()
        }
    }
    
    func loadRecommendArticleList() {
        APIRequest.getRecommendArticleListAPI(articleId: articleId, page: 1, row: 20) { (data) in
            self.recommendArticleList = data as? HomeArticleList
            self.tableView.reloadData()
        }
    }
    
    func loadCommentList() {
        APIRequest.commentListAPI(articleId: articleId, commentId: nil, page: 1) { [weak self](data) in
            self?.commentList = data as? CommentList
            self?.updateCommentBar()
        }
    }
    
    func loadRewardList() {
        APIRequest.ArticleReardManListAPI(articleId: articleId) { (data) in
//            if let rewardList = data as? RewardManList {
//                
//            }
            
        }
    }
    
    func updateView() {
        guard (article != nil) else {
            return
        }
        titleLb.text = article?.title
        authorNameLb.text = article?.publisher
        dateLb.text = article?.descString()
        subscriptBtn.isHidden = (article?.type != "normal")
        subscriptBtn.switchStateSub(article!.subseribe == 1)
        commentBar.collect(article!.collect == 1)
        let htmlString = NSString(string: baseHtmlString).replacingOccurrences(of: "${contentHtml}", with: article!.content)
        webView.loadHTMLString(htmlString, baseURL: URL(string: htmlString))
    }
    
    func updateCommentBar() {
        commentBar.commentBtn.setTitle(" \(commentList?.total ?? 0)", for: .normal)
    }
}
