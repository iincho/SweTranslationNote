//
//  DownloadLanguageViewController.swift
//  SweTranslationNote
//
//  Created by 本山洋一 on 2019/05/28.
//  Copyright © 2019 本山洋一. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMLCommon

enum DownloadState {
    case none
    case processing(Progress)
    case downloaded
}

struct DownloadLanguageObject {
    let type: TranslateLanguage
    var state: DownloadState
}

final class DownloadLanguageViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var dataList: [DownloadLanguageObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupObject()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44

        let nib = UINib(nibName: "DownloadLanguageCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Cell")
        tableView.reloadData()
        
        title = "Download Model"
        
        setupNotificationCenter()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "DeleteAll", style: .done, target: self, action: #selector(tapDeleteAll))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapDone))
    }
    
    @objc private func tapDone() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func tapDeleteAll() {
        let ac = UIAlertController(title: nil, message: "Delete All", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .destructive) { _ in
            let localModels = ModelManager.modelManager().availableTranslateModels(app: FirebaseApp.app()!)
            localModels.forEach { model in
                ModelManager.modelManager().deleteDownloadedTranslateModel(model) { [weak self] _ in
                    guard let sSelf = self,
                        let index = sSelf.dataList.firstIndex(where: {$0.type == model.language}) else { return }
                    sSelf.dataList[index].state = .none
                    sSelf.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                }
            }
        })
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(ac, animated: true, completion: nil)
    }
    
    private func setupNotificationCenter() {
        /// Success Download
        NotificationCenter.default.addObserver(forName: .firebaseMLModelDownloadDidSucceed,
                                               object: nil,
                                               queue: nil
        ) { [weak self] notification in
            guard let strongSelf = self,
                let userInfo = notification.userInfo,
                let model = userInfo[ModelDownloadUserInfoKey.remoteModel.rawValue] as? TranslateRemoteModel,
                let downloadedLanguageIndex = strongSelf.dataList.firstIndex(where: {$0.type == model.language}) else { return }
            // The model was downloaded and is available on the device
            strongSelf.dataList[downloadedLanguageIndex].state = .downloaded
            strongSelf.tableView.reloadRows(at: [IndexPath(row: downloadedLanguageIndex, section: 0)], with: .automatic)
        }
        
        /// Fail Download
        NotificationCenter.default.addObserver(forName: .firebaseMLModelDownloadDidFail,
                                               object: nil,
                                               queue: nil
        ) { [weak self] notification in
            guard let strongSelf = self,
                let userInfo = notification.userInfo,
                let model = userInfo[ModelDownloadUserInfoKey.remoteModel.rawValue] as? TranslateRemoteModel,
                let failLanguageIndex = strongSelf.dataList.firstIndex(where: {$0.type == model.language}) else { return }
            // Error
            let error = userInfo[ModelDownloadUserInfoKey.error.rawValue]
            let ac = UIAlertController(title: "Download Error", message: "\(strongSelf.dataList[failLanguageIndex].type.title!) Model Download did Fail \n\(error.debugDescription)", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            strongSelf.present(ac, animated: true, completion: nil)
            strongSelf.dataList[failLanguageIndex].state = .none
            strongSelf.tableView.reloadRows(at: [IndexPath(row: failLanguageIndex, section: 0)], with: .automatic)
        }
    }
    
    private func setupObject() {
        let localModels = ModelManager.modelManager().availableTranslateModels(app: FirebaseApp.app()!)
        
        dataList.removeAll()
        dataList = TranslateLanguage.allLanguages().map { lang -> DownloadLanguageObject in
            if let model = localModels.first(where: {$0.language.rawValue == lang.uintValue}) {
                return DownloadLanguageObject(type: model.language, state: .downloaded)
            } else {
                return DownloadLanguageObject(type: TranslateLanguage(rawValue: lang.uintValue)!, state: .none)
            }
        }
    }
}

extension DownloadLanguageViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! DownloadLanguageCell
        let data = dataList[indexPath.row]
        cell.configure(type: data.type, state: data.state)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = dataList[indexPath.row]
        switch data.state {
        case .downloaded:
            /// Delete Model
            tableView.reloadRows(at: [indexPath], with: .none)
            let deleteModel = TranslateRemoteModel.translateRemoteModel(language: data.type)
            ModelManager.modelManager().deleteDownloadedTranslateModel(deleteModel) { [weak self] error in
                let ac: UIAlertController!
                if let error = error {
                    ac = UIAlertController(title: "Delete Error", message: error.localizedDescription, preferredStyle: .alert)
                } else {
                    ac = UIAlertController(title: nil, message: "Delete Language Model", preferredStyle: .alert)
                    self?.dataList[indexPath.row].state = .none
                    self?.tableView.reloadRows(at: [indexPath], with: .none)
                }
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(ac, animated: true, completion: nil)
            }
        case .processing:
            break
        case .none:
            /// Download Model
            tableView.reloadRows(at: [indexPath], with: .automatic)
            let dlModel = TranslateRemoteModel.translateRemoteModel(
                app: FirebaseApp.app()!,
                language: data.type,
                conditions: ModelDownloadConditions(
                    allowsCellularAccess: true,
                    allowsBackgroundDownloading: true
            ))
            let progress = ModelManager.modelManager().download(dlModel)
            /// このprogressを監視しても0.0 or 1.0のどちらかしか返却されずProgressViewの更新には使えない
            dataList[indexPath.row].state = .processing(progress)
            if let cell = tableView.cellForRow(at: indexPath) as? DownloadLanguageCell {
                cell.configure(type: data.type, state: .processing(progress))
            }
        }
    }
}
