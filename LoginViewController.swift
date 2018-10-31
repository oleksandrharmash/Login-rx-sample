//
//  LoginViewController.swift
//
//  Created by Oleksandr Harmash
//  Copyright © Oleksandr Harmash. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SkyFloatingLabelTextField

private let loginViewAnimationDuration: TimeInterval = 0.5

class LoginViewController : BaseController {
    
    @IBOutlet weak var topBackgroundImageView: UIImageView!
    @IBOutlet weak var emailTextField : SkyFloatingLabelTextField!
    @IBOutlet weak var passwordTextField : SkyFloatingLabelTextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var createNewAccountButton: UIButton!
    
    var viewModel: LoginViewModel!
    
    let disposeBag = DisposeBag()
    
    //MARK: - Controller Life Circle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareModel()
        userNameFieldChangeUIWithRX()
        passwordFieldChangeUIWithRX()
        buttonsActionsUIWithRX()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    //MARK: - RX
    /// ViewModel setup
    private func prepareModel(){
        
        viewModel = LoginViewModel(usernameText: emailTextField.rx.text.orEmpty.asDriver(),
                                   passwordText: passwordTextField.rx.text.orEmpty.asDriver())
        viewModel.credentialsValid.drive(onNext: { [unowned self] valid in
            self.loginButton.isEnabled = valid
        }).addDisposableTo(disposeBag)
    }

    /// Text fields setup
    private func userNameFieldChangeUIWithRX() {
        viewModel.usernameBGColor.drive(onNext: { [unowned self] color in
            UIView.animate(withDuration: 0.2) {
                self.emailTextField.textColor = color
            }
        }).addDisposableTo(disposeBag)
        
        emailTextField.rx.controlEvent(.editingDidEndOnExit)
            .subscribe(onNext: { [unowned self] _ in
                self.passwordTextField.becomeFirstResponder()
            }).addDisposableTo(disposeBag)
    }
    
    private func passwordFieldChangeUIWithRX() {
        viewModel.passwordBGColor.drive(onNext: { [unowned self] color in
            UIView.animate(withDuration: 0.2) {
                self.passwordTextField.textColor = color
            }
        }).addDisposableTo(disposeBag)
        
        passwordTextField.rx.controlEvent(.editingDidEndOnExit)
            .subscribe(onNext: { [unowned self] _ in
                
                if self.loginButton.isEnabled {
                    self.proccedLoginResponse()
                }
            }).addDisposableTo(disposeBag)
    }
    
    //MARK: Buttons actions
    private func buttonsActionsUIWithRX() {
        
        /// Login action
        loginButton.rx.tap
            .throttle(ParamsDouble.TimeStopButtonAction.rawValue, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                self.proccedLoginResponse()
            })
            .addDisposableTo(disposeBag)
        
        /// SignUp action
        createNewAccountButton.rx.tap
            .throttle(ParamsDouble.TimeStopButtonAction.rawValue, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                self.router.login.presentSignUp()
            })
            .addDisposableTo(disposeBag)

        /// Forgot
        forgotPasswordButton.rx.tap
            .throttle(ParamsDouble.TimeStopButtonAction.rawValue, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                self.router.login.presentForgotPassword()
            })
            .addDisposableTo(disposeBag)
    }

    //MARK: Customize UI
    private func setupUI() {
        navigationController?.navigationBar.setGradientBackground(with: GradientColor.colors)
        topBackgroundImageView.backgroundGradient(with: GradientColor.colors)
        loginButton.cornerRadius = 5.0
        loginButton.setGradientImage(with: GradientColor.colors, state: .normal)
        loginButton.setTitleColor(UIColor.white, for: .normal)
        forgotPasswordButton.setTitleColor(GradientColor.teal, for: .normal)
        emailTextField.titleLabel.font = Font.with(name: .SFUITextLight, size: 10)
        passwordTextField.titleLabel.font = Font.with(name: .SFUITextLight, size: 10)
    }

    //MARK: ViewModel call API
    private func proccedLoginResponse() {
        viewModel.user.email = emailTextField.text!
        viewModel.user.password = passwordTextField.text!
        viewModel.login(router: router)
    }
}
