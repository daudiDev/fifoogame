//
//  EditProfileView.swift
//  Fifoo
//
//  Created by Daudi Sagala on 6/30/24.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @StateObject var socketClient = SocketClient.shared
    @EnvironmentObject var userProfileVM: UserProfileVM
    @EnvironmentObject var loginVM: AppManagerVM
    @State private var cancelAccountAlertIsShowing = false
    @State private var confirmDeactivation = false
    @State private var confirmDeletion = false
    @State private var hasUnsavedChanges = false
    @State private var unSavedChangesAlert = false
    @State private var hasUnsavedImageChanges = false
    @State private var image = UIImage()
    @State private var showSheet = false
    @State private var imageUrl: String = ""
    @State private var loadingImage = false
    @State private var imageMissing: Bool = false
    @State private var showProgress = false
    @State private var showAvatars = false
    @State private var waitingForResponse = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView {
                    //MARK: Edit Profile
                    
                    VStack {
                        //MARK: profile image/avatar
                        VStack(alignment: .center, spacing: 5) {
                            
                            if (!imageUrl.isEmpty && imageUrl != "none") {
                                
                                Text("Change Avatar")
                                    .modifier(TitleCustomColorView())
                                    .fontWeight(.bold)
                                
                            } else {
                                
                                if (imageMissing) {
                                    Text("Add Avatar")
                                        .foregroundStyle(Color.red)
                                        .fontWeight(.bold)
                                } else {
                                    Text("Add Avatar")
                                        .modifier(TitleCustomColorView())
                                        .fontWeight(.bold)
                                }
                                
                            }
                            
                            
                            HStack(alignment: .center, spacing: 5) {
                                Spacer()
                                Button(action: {
                                    //MARK: add image code
                                    showAvatars = true
                                })
                                {
                                    Text("From Avatars List")
                                        .fontWeight(.semibold)
                                        .font(.system(size: 14))
                                }
                                .sheet(isPresented: $showAvatars) {
                                    AvatarsListView(showAvatars: $showAvatars)
                                        .environmentObject(userProfileVM)
                                }
                                Spacer()
                                Text("|")
                                Spacer()
                                Button(action: {
                                    //MARK: add image code
                                    showSheet = true
                                })
                                {
                                    Text("From My Photos")
                                        .fontWeight(.semibold)
                                        .font(.system(size: 14))
                                }
                                Spacer()
                                
                            }
                            .sheet(isPresented: $showSheet) {
                                ImagePicker(sourceType: .photoLibrary, selectedImage: self.$image, hasUnsavedImageChanges: $hasUnsavedImageChanges, imageUrl: $socketClient.avatarImageUrl, loadingImage: $loadingImage)
                            }
                            .onChange(of: socketClient.avatarImageUrl) {_,newValue in
                                
                                socketClient.userProfile.imageUrl = newValue
                                
                            }
                            
                         
                            //provided images/avatar to choose from
                            HStack {
                                
                                if (!imageUrl.isEmpty && imageUrl != "none") {
                                    Button(action: {
                                        //MARK: add image code
                                        showAvatars = true
                                    })
                                    {
                                        AsyncImage(url: URL(string: imageUrl)) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: geometry.size.width * 0.5)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                
                                            } else if phase.error != nil {
                                                
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(Color.edf1f8)
                                                        .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.35)
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    VStack {
                                                        Spacer()
                                                        HStack {
                                                            Spacer()
                                                            Text("IMAGE")
                                                                .foregroundStyle(.white)
                                                                .font(.system(size: 20))
                                                                .fontWeight(.heavy)
                                                            Spacer()
                                                        }
                                                        Spacer()
                                                    }
                                                    .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.35)
                                                    .background(.clear)
                                                } //z
                                            }
                                            
                                        } //async
                                        
                                    }//btn
                                    
                                } else {
                                    
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.edf1f8)
                                            .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.35)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        VStack {
                                            Spacer()
                                            HStack {
                                                Spacer()
                                                Text("IMAGE")
                                                    .foregroundStyle(.white)
                                                    .font(.system(size: 20))
                                                    .fontWeight(.heavy)
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                        .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.35)
                                        .background(.clear)
                                    } //z
                                    
                                }
                                
                                
                                //Added image here
                                if (socketClient.avatarImageUrl != "none" && socketClient.avatarImageUrl != "") {
                                    
                                    VStack(alignment: .center) {
                                        HStack {
                                            Spacer()
                                            Text("AVATAR ADDED")
                                                .font(.system(size: 20))
                                                .foregroundStyle(Color.darkGreen)
                                                .fontWeight(.bold)
                                                .multilineTextAlignment(.center)
                                            Spacer()
                                        }
                                        
                                    }
                                    .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.35)
                                    
                                } else {
                                    VStack(alignment: .center) {
                                        Text("\(socketClient.avatars.count)")
                                            .font(.system(size: 20))
                                            .modifier(DarkCustomColorView())
                                            .fontWeight(.bold)
                                        Text("Avatars Available")
                                            .font(.system(size: 14))
                                            .modifier(DarkCustomColorView())
                                            .fontWeight(.bold)
                                    }
                                    .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.35)
                                    
                                } //iff
                                
                            } //hstack
                            
                        }
                        .padding()
                        
                        VStack(alignment: .leading, spacing: 20) {
                            
                            
                            HStack(alignment: .center, spacing: 5) {
                                HStack {
                                    Spacer()
                                    Text("Username")
                                        .fontWeight(.semibold)
                                        .modifier(DarkCustomColorView())
                                }
                                .frame(width: 100)
                                TextField("Username", text: $socketClient.userProfile.username)
                                    .textFieldStyle(.roundedBorder)
                                
                                
                                
                            }
                            .onChange(of: socketClient.userProfile.username) {_,newValue in
                                hasUnsavedChanges = true
                            }
                            
                            HStack(alignment: .center, spacing: 5) {
                                HStack {
                                    Spacer()
                                    Text("First Name")
                                        .fontWeight(.semibold)
                                        .modifier(DarkCustomColorView())
                                }
                                .frame(width: 100)
                                TextField("First Name", text: $socketClient.userProfile.firstName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .onChange(of: socketClient.userProfile.firstName) {_,newValue in
                                hasUnsavedChanges = true
                            }
                            
                            
                            HStack(alignment: .center, spacing: 5) {
                                HStack {
                                    Spacer()
                                    Text("Last Name")
                                        .fontWeight(.semibold)
                                        .modifier(DarkCustomColorView())
                                }
                                .frame(width: 100)
                                TextField("Last Name", text: $socketClient.userProfile.lastName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .onChange(of: socketClient.userProfile.lastName) {_,newValue in
                                hasUnsavedChanges = true
                            }
                            
                            
                            HStack(alignment: .center, spacing: 5) {
                                HStack {
                                    Spacer()
                                    Text("Phone")
                                        .fontWeight(.semibold)
                                        .modifier(DarkCustomColorView())
                                }
                                    .frame(width: 100)
                                TextField("Phone", text: $socketClient.userProfile.phone)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .onChange(of: socketClient.userProfile.phone) {_,newValue in
                                hasUnsavedChanges = true
                            }
                            
                            
                            HStack {
                                Spacer()
                                Button(action: {
                                    //MARK: save changes code
                                    
                                    userProfileVM.editProfile(
                                        username: socketClient.userProfile.username,
                                        firstName: socketClient.userProfile.firstName,
                                        lastName: socketClient.userProfile.lastName,
                                        phone: socketClient.userProfile.phone,
                                        imageUrl: socketClient.userProfile.imageUrl
                                    )
                                    
                                    waitingForResponse = false
                                    hasUnsavedChanges = false
                                    hasUnsavedImageChanges = false
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                       withAnimation {
                                           showProgress = true
                                       }
                                   }
                                   

                                })
                                { Text("Save Changes")
                                    //                                    .font(.system(size: 14))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            
                            
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $showProgress)
                        {
                            VStack {
                                Spacer()
                                HStack(alignment: .center, spacing: 3) {
                                    Spacer()
                                    Text(Image(systemName: "bolt.ring.closed"))
                                        .font(.system(size: 16, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Text("Updating Profile...")
                                        .font(.system(size: 16, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                Spacer()
                            }
                            .background(.blue)
                            .presentationDetents([.fraction(0.2)])
                            .onAppear {
                                // Delay for 3 seconds before hiding the view
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    withAnimation {
                                        showProgress = false
                                        self.mode.wrappedValue.dismiss()
                                       
                                    }
                                }
                            }
                            
                        }
                        
                        Divider()
                        
                        VStack(alignment: .center, spacing: 10) {
                            
                            Button(action: {
                                cancelAccountAlertIsShowing = true
                            })
                            { Text("Cancel My Account")
                                //                                .font(.system(size: 14))
                                    .fontWeight(.semibold)
                                    .modifier(DarkCustomColorView())
                            }
                            .alert("CANCEL ACCOUNT", isPresented: $cancelAccountAlertIsShowing, actions: {
                                Button("Temporarily deactivate account") {
                                    cancelAccountAlertIsShowing = false
                                    confirmDeactivation = true
                                    
                                }
                                Button("Delete account plus all personal data") {
                                    cancelAccountAlertIsShowing = false
                                    confirmDeletion = true
                                }
                                .frame(width: 300, height: 300)
                                
                                Button("Go Back", role: .cancel) {
                                    
                                }
                            }, message: {
                                Text("To proceed, please select from the two options below.")
                            })
                            .alert("DEACTIVATE ACCOUNT", isPresented: $confirmDeactivation, actions: {
                                Button("Deactivate account") {
                                    userProfileVM.cancelAccount(level: "deactivate")
                                    confirmDeactivation = false
                                    loginVM.logout()
                                }
                                Button("Go Back", role: .cancel) {
                                    
                                }
                            }, message: {
                                Text("You would like to temporarily deactivate your account. Your account record, along with associated personal data, will be saved for you until you return. Thank You.")
                            })
                            .alert("DELETE ACCOUNT", isPresented: $confirmDeletion, actions: {
                                Button("Delete account") {
                                    userProfileVM.cancelAccount(level: "delete")
                                    confirmDeletion = false
                                    loginVM.logout()
                                }
                                Button("Go Back", role: .cancel) {
                                    
                                }
                            }, message: {
                                Text("You would like to permanently delete your account. Your account record, along with associated personal data, will be permanently removed from our records. Thank You.")
                            })
                            
                        } //cancel account vstack
                        .padding(40)
                        
                    } //inner vstack
                    
                } //scrollview
                
                
            } //main vstack
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button(action: {
                            //MARK: add code here before going back
                            if (hasUnsavedChanges || hasUnsavedImageChanges) {
                                unSavedChangesAlert = true
                            } else {
                                self.mode.wrappedValue.dismiss()
                            }
                            
                        })
                        {
                            Text(Image(systemName: "chevron.backward"))
                                .fontWeight(.semibold)
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                                .padding()
                        }
                        .alert("UNSAVED CHANGES", isPresented: $unSavedChangesAlert, actions: {
                            Button("Save Changes") {
                                
                                userProfileVM.editProfile(
                                    username: socketClient.userProfile.username,
                                    firstName: socketClient.userProfile.firstName,
                                    lastName: socketClient.userProfile.lastName,
                                    phone: socketClient.userProfile.phone,
                                    imageUrl: socketClient.userProfile.imageUrl
                                )
                                
                                hasUnsavedChanges = false
                                self.mode.wrappedValue.dismiss()
                                
                            }
                            Button("Discard Changes", role: .cancel) {
                                self.mode.wrappedValue.dismiss()
                            }
                        }, message: {
                            Text("You have unsaved changes, what would you like to do?")
                        })
                        
                    }
                    
                    
                }
                ToolbarItem(placement: .principal) {
                    
                    Text("Edit Profile")
                        .font(.system(size: 20, design: .rounded))
                        .fontWeight(.bold)
                        .padding()
                        .foregroundColor(.blue)
                    
                }
                
            }
            
        }
        .onAppear {
            
            print(socketClient.userProfile.username)
        
            socketClient.requestAvatars()
            
            if (socketClient.userProfile.imageUrl != "" && socketClient.userProfile.imageUrl != "none") {
                
                socketClient.avatarImageUrl = socketClient.userProfile.imageUrl
                imageUrl = socketClient.avatarImageUrl
                
            } else {
                
                imageUrl = socketClient.avatars.first?.imageUrl ?? ""
                
            }
            
        }
        .onChange(of: socketClient.avatarImageUrl) {_,_ in
            
            imageUrl = socketClient.avatarImageUrl
            
        }
        
    }
}
