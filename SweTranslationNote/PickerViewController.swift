//
//  PickerViewController.swift
//  SweTranslationNote
//
//  Created by 本山洋一 on 2019/05/26.
//  Copyright © 2019 本山洋一. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMLCommon

final class PickerViewController: UIViewController {
    @IBOutlet weak var pickerView: UIPickerView!
    private var selectedLanguage: TranslateLanguage!
    private var selectedHandler: ((TranslateLanguage) -> Void)?
    
    override func viewDidLoad() {
        pickerView.delegate = self
        pickerView.dataSource = self
        setupPickerView()
    }
    
    func setup(selectedLanguage: TranslateLanguage, handler: @escaping ((TranslateLanguage) -> Void)) {
        self.selectedLanguage = selectedLanguage
        selectedHandler = handler
    }
    
    private func setupPickerView() {
        pickerView.selectRow(Int(selectedLanguage.rawValue), inComponent: 0, animated: false)
    }
    
    @IBAction func tapCancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func tapDone(_ sender: Any) {
        if let lang = TranslateLanguage(rawValue: UInt(pickerView.selectedRow(inComponent: 0))) {
            selectedHandler?(lang)
        }
        dismiss(animated: true, completion: nil)
    }
}

extension PickerViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return TranslateLanguage.allLanguages().count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let localModels = ModelManager.modelManager().availableTranslateModels(app: FirebaseApp.app()!)
        let language = TranslateLanguage(rawValue: UInt(row))!
        var title = language.title ?? "undefined"
        if let _ = localModels.first(where: {$0.language == language}) {
            title += " @"
        }
        return title
    }
}

extension TranslateLanguage {
    var title: String? {
        switch self {
        case .af: return "Afrikaans"
        case .ar: return "Arabic"
        case .be: return "Belarusian"
        case .bg: return "Bulgarian"
        case .bn: return "Bengali"
        case .ca: return "Catalan"
        case .cs: return "Czech"
        case .cy: return "Welsh"
        case .da: return "Danish"
        case .de: return "German"
        case .el: return "Greek"
        case .en: return "English"
        case .eo: return "Esperanto"
        case .es: return "Spanish"
        case .et: return "Estonian"
        case .fa: return "Persian"
        case .fi: return "Finnish"
        case .fr: return "French"
        case .ga: return "Irish"
        case .gl: return "Galician"
        case .gu: return "Gujarati"
        case .he: return "Hebrew"
        case .hi: return "Hindi"
        case .hr: return "Croatian"
        case .ht: return "Haitian"
        case .hu: return "Hungarian"
        case .id: return "Indonesian"
        case .is: return "Icelandic"
        case .it: return "Italian"
        case .ja: return "Japanese"
        case .ka: return "Georgian"
        case .kn: return "Kannada"
        case .ko: return "Korean"
        case .lt: return "Lithuanian"
        case .lv: return "Latvian"
        case .mk: return "Macedonian"
        case .mr: return "Marathi"
        case .ms: return "Malay"
        case .mt: return "Maltese"
        case .nl: return "Dutch"
        case .no: return "Norwegian"
        case .pl: return "Polish"
        case .pt: return "Portuguese"
        case .ro: return "Romanian"
        case .ru: return "Russian"
        case .sk: return "Slovak"
        case .sl: return "Slovenian"
        case .sq: return "Albanian"
        case .sv: return "Swedish"
        case .sw: return "Swahili"
        case .ta: return "Tamil"
        case .te: return "Telugu"
        case .th: return "Thai"
        case .tl: return "Tagalog"
        case .tr: return "Turkish"
        case .uk: return "Ukranian"
        case .ur: return "Urdu"
        case .vi: return "Vietnamese"
        case .zh: return "Chinese"
        case .invalid:
            return nil
        @unknown default:
            return nil
        }
    }
}
