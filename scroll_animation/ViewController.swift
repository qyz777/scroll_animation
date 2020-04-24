//
//  ViewController.swift
//  scroll_animation
//
//  Created by qiyizhong on 2020/4/24.
//  Copyright © 2020 qiyizhong. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        view.addSubview(button)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        button.frame = CGRect(x: 0, y: 100, width: 44, height: 44)
        button.center.x = view.center.x
        tableView.frame = CGRect(x: 0, y: 144, width: view.frame.width, height: view.frame.height)
    }
    
    @objc
    func didClickButton() {
        tableView.setContentOffset(CGPoint(x: 0, y: 500), duration: 0.25, timingFunction: .sineInOut) {
            print("动画完成")
        }
//        UIView.animate(withDuration: 0.25) {
//            self.tableView.setContentOffset(CGPoint(x: 0, y: 500), animated: false)
//        }
    }
    
    lazy var tableView: UITableView = {
        let view = UITableView()
        view.delegate = self
        view.dataSource = self
        view.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        return view
    }()
    
    lazy var button: UIButton = {
        let view = UIButton()
        view.setTitle("滚动", for: .normal)
        view.addTarget(self, action: #selector(didClickButton), for: .touchUpInside)
        view.setTitleColor(.black, for: .normal)
        return view
    }()
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
    }
    
}

