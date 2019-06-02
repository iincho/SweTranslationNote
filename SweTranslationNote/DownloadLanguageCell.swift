//
//  DownloadLanguageCell.swift
//  SweTranslationNote
//
//  Created by 本山洋一 on 2019/05/28.
//  Copyright © 2019 本山洋一. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMLCommon
import RxSwift
import RxCocoa
import RxOptional

class DownloadLanguageCell: UITableViewCell {

    var downloadHandler: (() -> Void)?

    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var dlStackView: UIStackView!
    @IBOutlet weak var downloadedLabel: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var dlLabel: UILabel!
    
    private let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        indicator.hidesWhenStopped = false
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func downloadLanguage(_ sender: Any) {
        downloadHandler?()
    }

    func configure(type: TranslateLanguage, state: DownloadState) {
        languageLabel.text = type.title
        
        downloadedLabel.isHidden = true
        dlLabel.isHidden = true
        indicator.isHidden = true
        progressView.isHidden = true
        switch state {
        case .downloaded:
            downloadedLabel.isHidden = false
        case .processing(let progress):
            indicator.isHidden = false
            indicator.startAnimating()
            progressView.isHidden = false
            progress.rx.observe(Double.self, "fractionCompleted")
                .filterNil()
                .map { Float($0) }
                .observeOn(MainScheduler.instance)
                .bind(to: progressView.rx.progress)
                .disposed(by: disposeBag)
        case .none:
            dlLabel.isHidden = false
        }
    }
}
