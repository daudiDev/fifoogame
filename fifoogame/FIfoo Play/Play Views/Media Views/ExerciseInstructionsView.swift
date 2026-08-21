//
//  ExerciseInstructionsView.swift
//  Fifoo Play
//
//  Created by Daudi Sagala on 8/13/26.
//


import SwiftUI


struct ExerciseInstructionsView: View {

    let exerciseName: String
    let instructions: ExerciseInstructions

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {

        NavigationStack {

            ScrollView {

                LazyVStack(
                    alignment: .leading,
                    spacing: 24
                ) {

                    // MARK: Demo Video

                    if let demoVideoURL =
                        instructions.demoVideoURL {

                        demoVideoSection(
                            url: demoVideoURL
                        )
                    }


                    // MARK: Steps

                    if !instructions.steps.isEmpty {

                        instructionStepsSection
                    }
                }
                .padding(.bottom, 40)
            }
            .background(
                Color(.systemBackground)
            )
            .navigationTitle(
                exerciseName
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {

                ToolbarItem(
                    placement: .topBarTrailing
                ) {

                    Button {

                        dismiss()

                    } label: {

                        Image(
                            systemName:
                                "xmark.circle.fill"
                        )
                        .font(.title2)
                        .foregroundStyle(
                            .secondary
                        )
                    }
                }
            }
        }
    }
}

private extension ExerciseInstructionsView {

    @ViewBuilder
    func demoVideoSection(
        url: URL
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("DEMONSTRATION")
                .font(
                    .system(
                        size: 13,
                        weight: .heavy,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    .secondary
                )
                .padding(.horizontal)


            ZStack {

                Color.black

                FullScreenVideoView(
                    url: url,
                    isActive: true
                )
            }
            .frame(height: 260)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20
                )
            )
            .padding(.horizontal)
        }
    }
}

private extension ExerciseInstructionsView {

    var instructionStepsSection: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            Text("HOW TO PERFORM")
                .font(
                    .system(
                        size: 13,
                        weight: .heavy,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    .secondary
                )
                .padding(.horizontal)


            ForEach(
                sortedSteps
            ) { step in

                ExerciseInstructionStepView(
                    step: step
                )
            }
        }
    }


    var sortedSteps:
        [ExerciseInstructionStep] {

        instructions.steps.sorted {

            $0.stepNumber <
                $1.stepNumber
        }
    }
}


struct ExerciseInstructionStepView: View {

    let step: ExerciseInstructionStep

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 16
        ) {

            // MARK: Step Number

            Text(
                "\(step.stepNumber)"
            )
            .font(
                .system(
                    size: 20,
                    weight: .heavy,
                    design: .rounded
                )
            )
            .foregroundStyle(.white)
            .frame(
                width: 44,
                height: 44
            )
            .background(
                Circle()
                    .fill(.blue)
            )


            // MARK: Instruction Content

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text(
                    step.instruction
                )
                .font(
                    .system(
                        size: 18,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(
                    .primary
                )


                if let detail =
                    step.detail,
                   !detail.isEmpty {

                    Text(detail)
                        .font(
                            .system(
                                size: 15,
                                weight: .regular,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(
                            .secondary
                        )
                }


                // MARK: Optional Step Image

                if let imageURL =
                    step.imageURL {

                    AsyncImage(
                        url: imageURL
                    ) { phase in

                        switch phase {

                        case .empty:

                            ProgressView()
                                .frame(
                                    maxWidth:
                                        .infinity
                                )
                                .frame(
                                    height: 180
                                )


                        case .success(
                            let image
                        ):

                            image
                                .resizable()
                                .scaledToFill()
                                .frame(
                                    maxWidth:
                                        .infinity
                                )
                                .frame(
                                    height: 180
                                )
                                .clipped()


                        case .failure:

                            Color.gray
                                .opacity(0.15)
                                .frame(
                                    height: 180
                                )


                        @unknown default:

                            EmptyView()
                        }
                    }
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16
                        )
                    )
                    .padding(.top, 4)
                }


                // MARK: Optional Step Video

                if let videoURL =
                    step.videoURL {

                    FullScreenVideoView(
                        url: videoURL,
                        isActive: true
                    )
                    .frame(
                        height: 180
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16
                        )
                    )
                    .padding(.top, 4)
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .padding(.horizontal)
    }
}
