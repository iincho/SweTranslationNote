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

class DownloadLanguageCell: UITableViewCell {

    var downloadHandler: (() -> Void)?

    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var dlStackView: UIStackView!
    @IBOutlet weak var downloadedLabel: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var dlLabel: UILabel!
    
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
        switch state {
        case .downloaded:
            downloadedLabel.isHidden = false
        case .processing:
            indicator.isHidden = false
            indicator.startAnimating()
        case .none:
            dlLabel.isHidden = false
        }
    }
}
