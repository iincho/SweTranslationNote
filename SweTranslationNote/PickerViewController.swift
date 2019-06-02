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
    
    func setup(selectedLanguage: TranslateLanguage, handler: ((TranslateLanguage) -> Void)?) {
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
        case .AF: return "Afrikaans"
        case .AR: return "Arabic"
        case .BE: return "Belarusian"
        case .BG: return "Bulgarian"
        case .BN: return "Bengali"
        case .CA: return "Catalan"
        case .CS: return "Czech"
        case .CY: return "Welsh"
        case .DA: return "Danish"
        case .DE: return "German"
        case .EL: return "Greek"
        case .EN: return "English"
        case .EO: return "Esperanto"
        case .ES: return "Spanish"
        case .ET: return "Estonian"
        case .FA: return "Persian"
        case .FI: return "Finnish"
        case .FR: return "French"
        case .GA: return "Irish"
        case .GL: return "Galician"
        case .GU: return "Gujarati"
        case .HE: return "Hebrew"
        case .HI: return "Hindi"
        case .HR: return "Croatian"
        case .HT: return "Haitian"
        case .HU: return "Hungarian"
        case .ID: return "Indonesian"
        case .IS: return "Icelandic"
        case .IT: return "Italian"
        case .JA: return "Japanese"
        case .KA: return "Georgian"
        case .KN: return "Kannada"
        case .KO: return "Korean"
        case .LT: return "Lithuanian"
        case .LV: return "Latvian"
        case .MK: return "Macedonian"
        case .MR: return "Marathi"
        case .MS: return "Malay"
        case .MT: return "Maltese"
        case .NL: return "Dutch"
        case .NO: return "Norwegian"
        case .PL: return "Polish"
        case .PT: return "Portuguese"
        case .RO: return "Romanian"
        case .RU: return "Russian"
        case .SK: return "Slovak"
        case .SL: return "Slovenian"
        case .SQ: return "Albanian"
        case .SV: return "Swedish"
        case .SW: return "Swahili"
        case .TA: return "Tamil"
        case .TE: return "Telugu"
        case .TH: return "Thai"
        case .TL: return "Tagalog"
        case .TR: return "Turkish"
        case .UK: return "Ukranian"
        case .UR: return "Urdu"
        case .VI: return "Vietnamese"
        case .ZH: return "Chinese"
        case .invalid:
            return nil
        @unknown default:
            return nil
        }
    }
}
