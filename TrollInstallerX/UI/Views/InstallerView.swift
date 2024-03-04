//
//  InstallerView.swift
//  TrollInstallerX
//
//  Created by Alfie on 02/03/2024.
//

import SwiftUI
import UIKit
import SwiftfulLoadingIndicators

import SwiftUI

func downloadKernelCacheAsync(url: String, isOTA: Bool, docsDir: String) async throws -> Bool {
    let result = await withUnsafeContinuation { continuation in
        DispatchQueue.global().async {
            let resultCode = download_kernelcache(url, isOTA, docsDir)
            continuation.resume(returning: resultCode)
        }
    }
    return result
}

struct InstallerView: View {
    
    /*
    arm64e:
    iOS 14.x: TrollHelperOTA
    iOS 15.0-16.1.2: MacDirtyCow
    iOS 15.0-16.5.1: kfd + XPF + dmaFail?
     
    arm64:
    iOS 14.x: kfd + XPF/IOSurface
    iOS 15.0-16.1.2: MacDirtyCow
    iOS 15.0-16.6.1: kfd + XPF
    */
    
    enum InstallationProgress: Equatable {
        case idle, downloadingKernel, patchfinding, exploiting, unsandboxing, escalatingPrivileges, installing, finished
    }
    
    struct MenuOption: Identifiable, Equatable {
        
        static func == (lhs: InstallerView.MenuOption, rhs: InstallerView.MenuOption) -> Bool {
            lhs.id == rhs.id
        }
        
        var id: String
        
        var imageName: String
        var title: String
        
        
        var action: (() -> ())? = nil
    }
    
    @State var isSettingsPresented = false
    @State var isCreditsPresented = false
    
    @State var installProgress: InstallationProgress = .idle
    @State var installationError: Error?
    
    @AppStorage("verboseLogging") var verboseLogging: Bool = false
    @State var verboseLoggingTemporary: Bool = false
    
    var isInstalling: Bool {
        installProgress != .idle
    }
    
    var requiresEnvironmentUpdate = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                
                let isPopupPresented = isSettingsPresented || isCreditsPresented
                
                
                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                    .scaleEffect(isPopupPresented ? 1.2 : 1.4)
                    .animation(.spring(), value: isPopupPresented)
                
                    VStack {
                        Spacer()
                        header
                        Spacer()
                        menu
                        if !isInstalling {
                            Spacer()
                            Spacer()
                        }
                        bottomSection
                        if !isInstalling {
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blur(radius: isPopupPresented ? 4 : 0)
                    .scaleEffect(isPopupPresented ? 0.85 : 1)
                    .animation(.spring(), value: isPopupPresented)
                    .transition(.opacity)
                    .zIndex(1)
                
                
                PopupView(title: {
                    Text("Settings")
                }, contents: {
                    SettingsView(isPresented: $isSettingsPresented)
                        .frame(maxWidth: 320)
                }, isPresented: $isSettingsPresented)
                .zIndex(2)
                
                
                PopupView(title: {
                    VStack(spacing: 4) {
                        Text("Made by")
                        Text("Alfie CG")
                            .font(.footnote)
                            .opacity(0.6)
                            .multilineTextAlignment(.center)
                    }
                }, contents: {
                    AboutView()
                        .frame(maxWidth: 320)
                }, isPresented: $isCreditsPresented)
                .zIndex(2)
            }
            .animation(.default, value: true)
        }
    }
    
    
    @ViewBuilder
    var header: some View {
            VStack {
                Image("TrollStore")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 100)
                    .cornerRadius(15.0)
                    .padding([.top, .horizontal])
                
                Text("TrollInstallerX")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text("iOS 14.0 - 16.6.1")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("made by Alfie CG")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                Text("DO NOT USE ICRAZEWARE")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            }
        .padding()
        .frame(maxWidth: 340, maxHeight: nil)
        .animation(.spring(), value: isInstalling)
    }
    
    @ViewBuilder
    var menu: some View {
        VStack {
            let menuOptions: [MenuOption] = [
                .init(id: "settings", imageName: "gearshape", title: NSLocalizedString("Settings", comment: "")),
                .init(id: "kernelcache", imageName: "folder.badge.plus", title: NSLocalizedString("Select kernelcache", comment: "")),
                .init(id: "credits", imageName: "info.circle", title: NSLocalizedString("Credits", comment: "")),
            ]
            ForEach(menuOptions) { option in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if let action = option.action {
                        action()
                    } else {
                        switch option.id {
                        case "settings":
                            isSettingsPresented = true
                        case "credits":
                            isCreditsPresented = true
                        default: break
                        }
                    }
                } label: {
                    HStack {
                        Label(title: { Text(option.title) }, icon: { Image(systemName: option.imageName) })
                            .foregroundColor(Color.white)
                        
                        Spacer()
                        
                        if option.action == nil {
                            Image(systemName: Locale.characterDirection(forLanguage: Locale.current.languageCode ?? "") == .rightToLeft ? "chevron.left" : "chevron.right")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color(red: 1, green: 1, blue: 1, opacity: 0.00001))
                }
                .buttonStyle(.plain)
                
                if menuOptions.last != option {
                    Divider()
                        .background(Color.white)
                        .opacity(0.5)
                        .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(MaterialView(.systemUltraThinMaterialDark))
        .cornerRadius(16)
        .frame(maxWidth: 320, maxHeight: isInstalling ? 0 : nil)
        .opacity(isInstalling ? 0 : 1)
        .animation(.spring(), value: isInstalling)
    }
    
    @ViewBuilder
    var bottomSection: some View {
        VStack {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                beginInstall()
            } label: {
                Label(title: {
                    switch installProgress {
                    case .idle:
                        Text("Install TrollStore")
                    case .downloadingKernel:
                        Text("Downloading kernelcache")
                    case .patchfinding:
                        Text("Patchfinding")
                    case .exploiting:
                        Text("Exploiting")
                    case .unsandboxing:
                        Text("Unsandboxing")
                    case .escalatingPrivileges:
                        Text("Escalating privileges")
                    case .installing:
                        Text("Installing TrollHelper")
                    case .finished:
                        if installationError == nil {
                            Text("Successfully installed")
                        } else {
                            Text("Unsuccessful")
                        }
                    }
                    
                }, icon: {
                    if !requiresEnvironmentUpdate {
                        ZStack {
                            switch installProgress {
                            case .finished:
                                if installationError == nil {
                                    Image(systemName: "lock.open")
                                } else {
                                    Image(systemName: "lock.slash")
                                }
                            case .idle:
                                Image(systemName: "lock.open")
                            default:
                                LoadingIndicator(animation: .doubleHelix, color: .white, size: .small)
                            }
                        }
                    } else {
                        Image(systemName: "doc.badge.arrow.up")
                    }
                })
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: isInstalling ? .infinity : 280)
            }
            .disabled(isInstalling)
            .drawingGroup()
            
            if installProgress == .finished || installProgress != .idle {
                Spacer()
                LogView(verboseLogsTemporary: $verboseLoggingTemporary, verboseLogging: $verboseLogging)
                endButtons
            }
        }
        .frame(maxWidth: isInstalling ? .infinity : 280, maxHeight: isInstalling ? UIScreen.main.bounds.height * 0.65 : nil)
        .padding(.horizontal, isInstalling ? 0 : 20)
        .padding(.top, isInstalling ? 16 : 0)
        .background(MaterialView(.systemUltraThinMaterialDark)
            .cornerRadius(isInstalling ? 20 : 8)
            .ignoresSafeArea(.all, edges: isInstalling ? .all : .top)
            .offset(y: isInstalling ? 16 : 0)
        )
        .animation(.spring(), value: isInstalling)
    }
    
    @ViewBuilder
    var endButtons: some View {
        switch installProgress {
        case .finished:
            if !verboseLogging, installationError != nil {
                Button {
                    verboseLoggingTemporary.toggle()
                } label: {
                    Label(title: { Text(verboseLoggingTemporary ? "Button_Hide_Logs_Title" : "Button_Show_Logs_Title") }, icon: {
                        Image(systemName: "scroll")
                    })
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 280, maxHeight: installationError != nil ? nil : 0)
                    .background(MaterialView(.light)
                        .opacity(0.5)
                        .cornerRadius(8)
                    )
                    .opacity(installationError != nil ? 1 : 0)
                }
            }
        case .idle:
            Group {}
        default:
            Group {}
        }
    }
    
    func beginInstall() {
        
        Task {
            installProgress = .downloadingKernel
            Logger.log("Determining IPSW URL", isStatus: true)
            var isOTA = false
            let url = getFirmwareURL(&isOTA)
            guard url != nil else {
                Logger.log("Failed to find IPSW URL!", type: .error)
                return
            }
            Logger.log("Successfully retrieved IPSW URL!", type: .continuous, isStatus: true)
            
            let fileManager = FileManager.default
            let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].path
            try? fileManager.removeItem(atPath: docsDir + "/kernelcache")
            
            installProgress = .downloadingKernel
            
            Logger.log("Downloading kernelcache", isStatus: true)
            let ret = try await downloadKernelCacheAsync(url: url!, isOTA: isOTA, docsDir: docsDir)
            if !ret {
                print("Failed to download kernelcache file!")
                return
            }
            
            installProgress = .patchfinding
            
            Logger.log("Patchfinding kernel", isStatus: true)
            patchfind_kernel(docsDir + "/kernelcache")
            
            installProgress = .exploiting
            Logger.log("Exploiting kernel", isStatus: true)
        }
    }
}

struct JailbreakView_Previews: PreviewProvider {
    static var previews: some View {
        InstallerView()
    }
}
