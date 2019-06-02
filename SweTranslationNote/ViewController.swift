//
//  ViewController.swift
//  SweTranslationNote
//
//  Created by 本山洋一 on 2019/05/18.
//  Copyright © 2019 本山洋一. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMLCommon
import SnapKit
import RxSwift
import RxRelay
import RxCocoa

class ViewController: UIViewController {
    enum ChangeLanguageSegueType: String {
        case input = "toChangeInputLanguage"
        case output = "toChangeOutputLanguage"
    }
    let downloadIdentifier = "toDownloadLanguage"

    enum TranslateState {
        case none, modelDownloading, translationing
        
        var title: String {
            switch self {
            case .none: return "↓"
            case .modelDownloading: return "Model Downloading..."
            case .translationing: return "Translationing..."
            }
        }
        var isHiddenIndicator: Bool {
            switch self {
            case .none: return true
            case .modelDownloading, .translationing: return false
            }
        }
    }

    @IBOutlet weak var footerView: UIStackView!
    
    @IBOutlet weak var inputLanguageView: UIView!
    @IBOutlet weak var inputLanguageButton: UIButton!
    @IBOutlet weak var inputTextView: UITextView!
    
    @IBOutlet weak var outputLanguageView: UIView!
    @IBOutlet weak var outputLanguageButton: UIButton!
    @IBOutlet weak var outputTextView: UITextView!
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var translateStateLabel: UILabel!
    
    private var inputLanguage: TranslateLanguage = .JA
    private var outputLanguage: TranslateLanguage = .EN
    
    private var translateStateRelay = BehaviorRelay<TranslateState>(value: .none)
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        clearTextView()
        setupNotificationCenter()
    }
    
    private func setupViews() {
        inputTextView.layer.borderColor = UIColor.gray.cgColor
        inputTextView.layer.borderWidth = 1
        inputTextView.layer.cornerRadius = 4
        
        outputTextView.layer.borderColor = UIColor.gray.cgColor
        outputTextView.layer.borderWidth = 1
        outputTextView.layer.cornerRadius = 4
        
        refreshLanguage()
        
        translateStateRelay
            .asDriver()
            .distinctUntilChanged()
            .drive(onNext: { [weak self] value in
                self?.translateStateLabel.text = value.title
                self?.indicator.isHidden = value.isHiddenIndicator
                if !value.isHiddenIndicator { self?.indicator.startAnimating() }
            }).disposed(by: disposeBag)
        
        inputTextView.rx.text
            .orEmpty
            .distinctUntilChanged()
            .debounce(.milliseconds(400), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.translation()
            }).disposed(by: disposeBag)
    
        title = "Translation"
    }
    
    func refreshLanguage() {
        inputLanguageButton.setTitle(inputLanguage.title, for: .normal)
        outputLanguageButton.setTitle(outputLanguage.title, for: .normal)
    }
    
    func setupNotificationCenter() {
        let notification = NotificationCenter.default
        notification.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                 name: UIResponder.keyboardWillShowNotification, object: nil)
        notification.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                 name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification?) {
        guard let rect = (notification?.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let keyboardHeight = rect.size.height
        footerView.snp.remakeConstraints { make in
            make.bottom.equalToSuperview().inset(keyboardHeight)
        }
        view.layoutIfNeeded()
    }
    
    @objc func keyboardWillHide(_ notification: Notification?) {
        footerView.snp.remakeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    @IBAction func tapChangeInputLanguage(_ sender: Any) {
        performSegue(withIdentifier: ChangeLanguageSegueType.input.rawValue, sender: sender)
    }
    
    @IBAction func tapChangeOutputLanguage(_ sender: Any) {
        performSegue(withIdentifier: ChangeLanguageSegueType.output.rawValue, sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Transition PickerViewController
        if let vc = segue.destination as? PickerViewController,
            let identifier = segue.identifier,
            let type = ChangeLanguageSegueType(rawValue: identifier) {
            vc.setup(selectedLanguage: getSelectedLanguage(type: type)) { [unowned self] language in
                switch type {
                case .input:
                    self.inputLanguage = language
                case .output:
                    self.outputLanguage = language
                }
                self.refreshLanguage()
                self.outputTextView.text = ""
                self.translation()
            }
        }
        
        // Transition DownloadLanguageViewController
        if let _ = segue.destination as? DownloadLanguageViewController {}
    }
    
    private func getSelectedLanguage(type: ChangeLanguageSegueType) -> TranslateLanguage {
        switch type {
        case .input:
            return inputLanguage
        case .output:
            return outputLanguage
        }
    }
    
    @IBAction func tapClear(_ sender: Any) {
        inputTextView.resignFirstResponder()
        clearTextView()
    }
    
    @IBAction func tapTranslation(_ sender: Any) {
        inputTextView.resignFirstResponder()
        translation()
    }
    
    private func clearTextView() {
        inputTextView.text = ""
        outputTextView.text = ""
    }
    
    private func translation() {
        print("**start translation**")
        
        translateStateRelay.accept(.modelDownloading)
        let options = TranslatorOptions(sourceLanguage: inputLanguage, targetLanguage: outputLanguage)
        let translator = NaturalLanguage.naturalLanguage().translator(options: options)
        
        let conditios = ModelDownloadConditions(allowsCellularAccess: true, allowsBackgroundDownloading: true)
        
        translator.downloadModelIfNeeded(with: conditios) { [weak self] error in
            guard let sSelf = self else { return }
            if let error = error {
                sSelf.translateStateRelay.accept(.none)
                sSelf.outputTextView.text = "Download Error: \(error.localizedDescription)"
                return
            }
            
            sSelf.translateStateRelay.accept(.translationing)
            translator.translate(sSelf.inputTextView.text) { translatedText, error in
                sSelf.translateStateRelay.accept(.none)
                guard error == nil, let translatedText = translatedText else {
                    sSelf.outputTextView.text = "Translation Error: \(String(describing: error))"
                    return
                }
                sSelf.outputTextView.text = translatedText
                
                print("**end translation**")
            }
        }
    }
    
}

