//
//  NewUserSetUpView.swift
//  Fifoo
//
//  Created by Daudi Sagala on 6/30/24.
//

import SwiftUI

struct NewUserSetUpView: View {
    @StateObject var socketClient = SocketClient.shared
    @EnvironmentObject var  userProfileVM : UserProfileVM
    @EnvironmentObject var loginVM: AppManagerVM
    @State private var hasUnsavedChanges = false
    @Binding var profileChanged: String
    @State private var firstNameIsEmpty = false
    @State private var lastNameIsEmpty = false
    @State private var imageMissing: Bool = false
    @State private var showProgress = false
    @State private var hasUnsavedImageChanges = false
    @State private var image = UIImage()
    @State private var showSheet = false
    @State private var showAvatars = false
    @State private var loadingImage = false
    @State private var imageUrl: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                Form {
                    
                    Section(header: Text("Full Name").fontWeight(.bold)) {
                        if (firstNameIsEmpty) {
                            TextField("First Name", text:  $userProfileVM.firstName)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red, lineWidth: 1))
                        } else {
                            TextField("First Name", text:  $userProfileVM.firstName)
                                .padding()
                        }
                        
                        if (lastNameIsEmpty) {
                            TextField("Last Name", text:  $userProfileVM.lastName)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red, lineWidth: 1))
                            
                        } else {
                            TextField("Last Name", text:  $userProfileVM.lastName)
                                .padding()
                        }
                        
                    }
                    
                    //add image here
                    
                    if (imageMissing) {
                        Text("Add Avatar")
                            .foregroundStyle(Color.red)
                            .fontWeight(.semibold)
                    } else {
                        Text("Add Avatar")
                            .modifier(TitleCustomColorView())
                            .fontWeight(.semibold)
                    }
        
                    
                    HStack(alignment: .center, spacing: 5) {
                        Spacer()
                        Button(action: {
                            //MARK: add image code
                            showSheet = false
                            showAvatars = true
                        })
                        {
                            Text("From Below")
                        }
                        .fullScreenCover(isPresented: $showAvatars, onDismiss: {
                            
                            showSheet = false
                            showAvatars = false
                            
                        }) {
                            AvatarsListView(showAvatars: $showAvatars)
                              
                        }
                        Spacer()
                        Text("|")
                        Spacer()
                        Button(action: {
                            //MARK: add image code
                            showAvatars = false
                            showSheet = true
                       
                        })
                        {
                            Text("From My Photos")
                        }
                        .fullScreenCover(isPresented: $showSheet, onDismiss: {
                            
                            showSheet = false
                            showAvatars = false
                            
                        }) {
                            ImagePicker(sourceType: .photoLibrary, selectedImage: self.$image, hasUnsavedImageChanges: $hasUnsavedImageChanges, imageUrl: $socketClient.avatarImageUrl, loadingImage: $loadingImage)
                        }
                        
                        Spacer()
                        
                    }
                
                    .onChange(of: socketClient.avatarImageUrl) {_,newValue in
                        userProfileVM.imageUrl = newValue
                    }
                    
                        //provided images/avatar to choose from
                        HStack {
                            
                            if (!imageUrl.isEmpty && imageUrl != "none") {
                                
                                Button(action: {
                                    showAvatars = true
                                })
                                {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.edf1f8)
                                            .frame(width: geometry.size.width * 0.52, height: geometry.size.width * 0.52)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
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
                                        
                                    } //zs
                                    
                                }
                                
                                
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
                                                .foregroundStyle(.gray)
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
                                            .font(.system(size: 18))
                                            .foregroundStyle(Color.darkGreen)
                                            .fontWeight(.bold)
                                            .multilineTextAlignment(.center)
                                        Spacer()
                                    }
                                   
                                }
                                .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.35)
                                
                            } else {
                                Button(action: {
                                    showAvatars = true
                                })
                                {
                                    VStack(alignment: .center) {
                                        Text("\(socketClient.avatars.count)")
                                            .font(.system(size: 20))
                                            .modifier(DarkCustomColorView())
                                            .fontWeight(.bold)
                                        Text("Avatars")
                                            .font(.system(size: 14))
                                            .modifier(DarkCustomColorView())
                                            .fontWeight(.bold)
                                        Text("Available")
                                            .font(.system(size: 14))
                                            .modifier(DarkCustomColorView())
                                            .fontWeight(.bold)
                                    }
                                    .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.35)
                                }
                                
                            } //iff
                            
                        } //hstack
                        
                    
                    Section {
                        
                        Button(action: {
                            // Handle form submission
                            if (!userProfileVM.firstName.isEmpty || !userProfileVM.lastName.isEmpty || !imageUrl.isEmpty || imageUrl != "none") {
                                
                                userProfileVM.editProfile(
                                    username: userProfileVM.firstName,
                                    firstName: userProfileVM.firstName,
                                    lastName: userProfileVM.lastName,
                                    phone: userProfileVM.phone,
                                    imageUrl: imageUrl
                                )
                                
                                profileChanged = ""
                                
                            } else {
                                if (userProfileVM.firstName.isEmpty) {
                                    
                                    firstNameIsEmpty = true
                                    
                                }
                                
                                if (userProfileVM.lastName.isEmpty) {
                                    
                                    lastNameIsEmpty = true
                                    
                                }
                                
                                if (imageUrl.isEmpty || imageUrl == "none") {
                                    
                                    imageMissing = true
                                    
                                }
                            }
                                
                           
                          
                            
                        })
                        {
                            Text("Save")
                                .fontWeight(.semibold)
                            
                        }
                        
                    }
                    .frame(maxWidth: .infinity)
                    .onChange(of: userProfileVM.firstName) { _,_ in
                        firstNameIsEmpty = false
                    }
                    .onChange(of: userProfileVM.lastName) { _,_ in
                        lastNameIsEmpty = false
                    }
                    
                    
                }
                
                .toolbar {

                    ToolbarItem(placement: .principal) {
                        //MARK: make it dynamic
                        Text("Please Add Profile")
                            .font(.system(size: 18, design: .rounded))
                            .fontWeight(.heavy)
                            .padding(.vertical)
                            .modifier(DarkCustomColorView())
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            //MARK: close
                            
                            profileChanged = ""
                            
                        })
                        {
                            Image(systemName: "xmark")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .fontWeight(.thin)
                                .padding([.vertical, .horizontal])
                                .padding(.trailing)
                            
                        }
                    }
                } //end of toolbar
                .onAppear {

                    profileChanged = "changed"
                    socketClient.requestAvatars()
                    
                    if (socketClient.userProfile.imageUrl != "" && socketClient.userProfile.imageUrl != "none") {
                        
                        socketClient.avatarImageUrl = userProfileVM.imageUrl
                        imageUrl = socketClient.avatarImageUrl
                        
                    } else {
                        
                        imageUrl = socketClient.avatars.first?.imageUrl ?? ""
                        
                    }
                    
                }
                .onChange(of: socketClient.avatarImageUrl) {_,_ in
                    
                    imageUrl = socketClient.avatarImageUrl
                    
                }
                
            } //nav
            
        } //geometry
        
    }
}

