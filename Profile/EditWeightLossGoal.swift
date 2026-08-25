//
//  EditWeightLossGoal.swift
//  fifoo
//
//  Created by Daudi Sagala on 10/3/24.
//

import SwiftUI

struct EditWeightLossGoal: View {
    @StateObject var socketClient = SocketClient.shared
    @Binding var showEditGoal: Bool
    var geometry: GeometryProxy

    let periodArray = ["Select Period", "1 week", "2 weeks", "3 weeks", "4 weeks", "5 weeks", "6 weeks", "7 weeks", "8 weeks", "9 weeks", "10 weeks", "2 months", "3 months", "4 months", "5 months", "6 months", "7 months", "8 months", "9 months", "10 months", "11 months", "1 year", "2 years", "3 years", "4 years", "5 years"]
    
    @State private var selectedPeriodIndex: Int = 0
    @State private var missingGoal = false
    
    var body: some View {
        VStack {
            Spacer()
            if (missingGoal) {
                
                Text("I Want to Lose")
                    .font(.system(size: 20))
                    .fontWeight(.heavy)
                    .foregroundStyle(.red)
                
            } else {
                
                Text("I Want to Lose")
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                
            }
            
            Picker(selection: $socketClient.weightLossNumber, label: Text("Select a Number")) {
                ForEach(0..<200) { number in
                    Text("\(number) lbs").tag(number)
                }
            }
            .labelsHidden()
            .pickerStyle(WheelPickerStyle())
            .frame(height: 100)
            .onChange(of: socketClient.weightLossNumber) {_,_ in
                
                missingGoal = false
                
            }
            
            Text("In")
                .font(.system(size: 20))
                .fontWeight(.bold)
            
            Picker(selection: $selectedPeriodIndex, label: Text("")) {
                ForEach(0..<periodArray.count, id: \.self) { index in
                    Text(periodArray[index]).tag(index)
                }
            }
            .labelsHidden()
            .pickerStyle(WheelPickerStyle())
            .frame(height: 100)
            .onChange(of: selectedPeriodIndex) {_,_ in
                
                socketClient.weightLossPeriod = periodArray[selectedPeriodIndex]
                missingGoal = false
            }
            
            Spacer()
            HStack (alignment: .center, spacing: 5) {
                
                Button(action: {
                
                    showEditGoal = false
                    
                }) {
                    HStack {
                        Text("Go Back")
                            .font(.system(size: 16))
                            .fontWeight(.bold)
                            .frame(width: geometry.size.width * 0.44)
                    }
                    .padding(.vertical, 12)
                    .foregroundColor(.black)
                    .background(Color.lightGray)
                    .cornerRadius(10)
                }
                Spacer()
                Button(action: {
                    // Run code before navigating
                    
                    if (socketClient.weightLossNumber > 0 && socketClient.weightLossPeriod != ""
                        && socketClient.weightLossPeriod != "none"
                        && socketClient.weightLossPeriod != "Select Period") {
                        
                        socketClient.saveUserWeightGoals()
                        showEditGoal = false
                        
                    } else {
                        
                        missingGoal = true
                        
                    }
                    
                    
                }) {
                    HStack {
                        Text("Save Changes")
                            .font(.system(size: 16))
                            .fontWeight(.bold)
                            .frame(width: geometry.size.width * 0.44)
                    }
                    .padding(.vertical, 12)
                    .foregroundColor(.white)
                    .background(Color.darkGreen)
                    .cornerRadius(10)
                }
                
            }
            .padding([.top, .horizontal])
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
        .onAppear {
            
            socketClient.requestWeightLossGoal()
            
            if let index = periodArray.firstIndex(of: socketClient.weightLossPeriod) {
                
                selectedPeriodIndex = index
                
            }
            
        }
    }
}

