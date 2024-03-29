//
//  LoginView.swift
//  DreamCalendar
//
//  Created by 이지수 on 2023/01/03.
//

import SwiftUI
import Network

protocol InputableField: View {
    init(_ titleKey: LocalizedStringKey, text: Binding<String>)
}

extension SecureField: InputableField where Label == Text { }
extension TextField: InputableField where Label == Text { }

struct LoginView: View {
    
    private struct Constraint {
        static let zeroPadding: CGFloat = 0
        
        static let fields: [InputFieldType] = [.email, .password]
        
        static let inputFieldHeight: CGFloat = 127
        
        static let loginMessageTopPadding: CGFloat = 5
        static let alertButtonName: String = "확인"
        static let defaultErrorMessage: String = "로그인 중 오류가 발생했습니다."
        
        static let buttonName: String = "로그인"
        static let buttonTopPadding: CGFloat = 34
        
        static let findIdPwButtonName: String = "아이디/비밀번호 찾기"
        static let signupButtonName: String = "회원가입"
        
        static let accountOptionButtonsTopPadding: CGFloat = 8
        static let accountOptionButtonsHeight: CGFloat = 25
        static let accountOptionButtonsWidth: CGFloat = 264
    }
    
    private struct SmallTextButton: View {
        
        private struct Constraint {
            static let zeroPadding: CGFloat = 0
            static let leadingTrailingPadding: CGFloat = 4
            static let lineHeight: CGFloat = 12
        }
        
        private var title: String
        private var action: () -> Void
        
        init(title: String, action: @escaping () -> Void) {
            self.title = title
            self.action = action
        }
        
        var body: some View {
            Button(action: self.action) {
                Text(self.title)
                    .font(.AppleSDRegular12)
                    .foregroundColor(.black)
                    .lineSpacing(Constraint.lineHeight)
            }
            .padding(EdgeInsets(top: Constraint.zeroPadding,
                                leading: Constraint.leadingTrailingPadding,
                                bottom: Constraint.zeroPadding,
                                trailing: Constraint.leadingTrailingPadding))
        }
    }
    
    @ObservedObject private var viewModel: LoginViewModel
    @State private var doSignup: Bool
    #if DEVELOP
    @State private var isDevelopSettingMode: Bool = false
    #endif
    @FocusState private var focusedField: InputFieldType?
    
    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        self.doSignup = false
    }
    
    var body: some View {
        #if DEVELOP
        ZStack(alignment: .topLeading) {
            self.adminSettingButton
        }
        .sheet(isPresented: self.$isDevelopSettingMode) {
            DevLoginSettingsView()
        }
        #endif
        VStack(alignment: .center, spacing: Constraint.zeroPadding) {
            self.inputField
            ZStack(alignment: .top) {
                if AccountManager.global.didLogin == false && self.viewModel.loginMessage != nil {
                    self.loginMessage
                }
                self.loginButton
            }
            self.accountOptionButtons
        }
        .alert(DCError.title, isPresented: self.$viewModel.didError, actions: {
            Button(Constraint.alertButtonName) {
                self.viewModel.didError = false
            }
        }, message: {
            Text(self.viewModel.error?.localizedDescription ?? DCError.unknown.message)
        })
        .fullScreenCover(isPresented: self.$doSignup, content: {
            SignupView(doSignup: self.$doSignup)
        })
    }
    
    private var inputField: some View {
        VStack(spacing: Constraint.zeroPadding) {
            ForEach(Constraint.fields, id: \.hashValue) { field in
                if let bindingValue = field.bindingValue(with: self.$viewModel) {
                    field.fieldView(with: bindingValue)
                        .onSubmit {
                            self.focusedField = self.nextField(withCurrentField: field)
                        }
                        .focused(self.$focusedField, equals: field)
                }
                if (field != InputFieldType.allCases.last) {
                    Spacer()
                }
            }
        }
        .frame(height: Constraint.inputFieldHeight, alignment: .center)
        .padding(.zero)
    }
    
    private var loginMessage: some View {
        Text(self.viewModel.loginMessage ?? Constraint.defaultErrorMessage)
            .font(.AppleSDRegular12)
            .foregroundColor(.red)
            .frame(alignment: .center)
            .padding(EdgeInsets(top: Constraint.loginMessageTopPadding,
                                leading: Constraint.zeroPadding,
                                bottom: Constraint.zeroPadding,
                                trailing: Constraint.zeroPadding))
    }
    
    private var loginButton: some View {
        AccountConfirmButton(fieldName: Constraint.buttonName, action: self.loginButtonDidTouched)
            .padding(EdgeInsets(top: Constraint.buttonTopPadding,
                                leading: Constraint.zeroPadding,
                                bottom: Constraint.zeroPadding,
                                trailing: Constraint.zeroPadding))
    }
    
    private var accountOptionButtons: some View {
        HStack(alignment: .center) {
            SmallTextButton(title: Constraint.findIdPwButtonName, action: self.findIdPwButtonDidTouched)
            Spacer()
            SmallTextButton(title: Constraint.signupButtonName, action: self.signupButtonDidTouched)
        }
        .frame(width: Constraint.accountOptionButtonsWidth, height: Constraint.accountOptionButtonsHeight)
        .padding(EdgeInsets(top: Constraint.accountOptionButtonsTopPadding,
                            leading: Constraint.zeroPadding,
                            bottom: Constraint.zeroPadding,
                            trailing: Constraint.zeroPadding))
    }
    
    #if DEVELOP
    private var adminSettingButton: some View {
        let imageTitle = "개발자 설정"
        let height: CGFloat = 25
        
        return Button {
            self.isDevelopSettingMode = true
        } label: {
            Text(imageTitle)
        }
        .frame(height: height)
    }
    #endif
    
    private func loginButtonDidTouched() {
        Task {
            await self.viewModel.login()
        }
    }
    
    // TODO: 아이디 비밀번호 찾기 버튼 동작 구현 필요
    private func findIdPwButtonDidTouched() {
        print("find Id/Pw button touched")
    }
    
    private func signupButtonDidTouched() {
        self.doSignup = true
        self.viewModel.resetLoginStatus()
    }
    
    private func nextField(withCurrentField currentField: InputFieldType) -> InputFieldType? {
        switch currentField {
        case .email :
            return .password
        default :
            return nil
        }
    }
}

fileprivate extension InputFieldType {
    func bindingValue(with viewModel: ObservedObject<LoginViewModel>.Wrapper) -> Binding<String>? {
        switch self {
        case .email : return viewModel.email
        case .password : return viewModel.password
        default : return nil
        }
    }
}
