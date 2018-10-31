//
//  LoginViewModel.swift
//
//  Created by Oleksandr Harmash
//  Copyright © Oleksandr Harmash. All rights reserved.
//

import RxSwift
import RxCocoa
import RxSwiftUtilities

let DECLINE_COLOR = UIColor.red
let ACCESS_COLOR = UIColor.black

class LoginViewModel : ViewModelRx, APIOperationsProtocol {
    
    let usernameBGColor: Driver<UIColor>
    let passwordBGColor: Driver<UIColor>
    let credentialsValid: Driver<Bool>
    let user = User()
    
    init(usernameText: Driver<String>, passwordText: Driver<String>) {
        
        let usernameValid = usernameText
            .distinctUntilChanged()
            .throttle(0.2)
            .map { $0.isValidEmail() }
        
        let passwordValid = passwordText
            .distinctUntilChanged()
            .throttle(0.2)
            .map { $0.utf8.count > 7 }
        
        usernameBGColor = usernameValid
            .map { $0 ? ACCESS_COLOR : DECLINE_COLOR }
        
        passwordBGColor = passwordValid
            .map { $0 ? ACCESS_COLOR : DECLINE_COLOR }
        
        credentialsValid = Driver.combineLatest(usernameValid, passwordValid) { $0 && $1 }
        
        super.init()
        prepareActitivityIndiator()
    }
    
    func login(router:RouterModel) {
        
        let params = user.toJSON()
        
        simpleAPICall(method: .POST, modelType: UserLoginModel.self, params: params, headers: ResponseHeaderModel.defaultHeader)
            .subscribe(onNext: {[unowned self] model in
                
                /// Save token in keychain
                KeychainModel.saveInKeychaine(parameter: model.token, key: KeychainKeys.bearer)
                self.pushToken(router, model)
                
                self.successfulLogin(email: model.user.email, userTeam: model.user.userTeam, userId: model.user.uid, firstName: model.user.first_name, lastName: model.user.last_name)
            }).addDisposableTo(self.disposeBag)
    }
    
    private func pushToken(_ router:RouterModel, _ userModel: UserLoginModel) {
        let tokenModel = PushTokenItem()
        tokenModel.token = AppSettings.shared.getData(AppSettings.shared.userDefaultFireBaseAccessToken)
        let params = tokenModel.toJSON()
        
        simpleAPICall(method: .POST, modelType: PushTokenModel.self, params: params, headers: ResponseHeaderModel.bearerHeader)
            .subscribe(onNext: {[unowned self] model in
                
                /// Check if user in team
                if userModel.user.userTeam {
                    
                    // Check if challenge already set
                    if let _ = ChallengeManager.shared.getDefaults(model: StepsModel.self, archivedKey: .activityChallenge) {
                        if let _ = KeychainModel.getTracker() {
                            router.setupRoot(viewController: TabBarController())
                        } else {
                            self.getChallengeAndShowTrackerSelection(router: router)
                        }
                    } else {
                        self.getChallengeAndShowTrackerSelection(router: router)
                    }
                } else {
                    router.dashboard.presentSecurityCode()
                }
            }).addDisposableTo(self.disposeBag)
    }
    
    /// Get current challenge and open tracker selection
    private func getChallengeAndShowTrackerSelection(router: RouterModel) {
        ChallengeManager.shared.currentChallengeResponse().subscribe(onNext: {_ in
            router.dashboard.presentRootTrackersSelection()
        }).addDisposableTo(self.disposeBag)
    }
}
