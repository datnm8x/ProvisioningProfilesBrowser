import SwiftUI

struct ContentView: View {
  @EnvironmentObject var profilesManager: ProvisioningProfilesManager
  @State private var selectedProfileID: ProvisioningProfile.ID?
  @State private var selectionRows: [Int] = []

  var body: some View {
    VSplitView {
      ProfilesList(data: $profilesManager.visibleProfiles, selectedID: $selectedProfileID, selectionRows: $selectionRows)

      if let selectedProfileID = selectedProfileID,
         let profile = profilesManager.visibleProfiles.first(where: { $0.id == selectedProfileID }) {
        if let htmlString = GenerateHTMLForProfile.generateHTMLPreviewForProfile(profile) {
          ProfilePreviewView(htmlString: htmlString)
        } else {
          QuickLookPreview(url: profile.url)
        }
      } else {
        Color(.windowBackgroundColor)
      }
    }
    .onAppear(perform: profilesManager.reload)
    .frame(minWidth: 300, minHeight: 300)
    .alert(isPresented: $profilesManager.error.isNotNil) {
      Alert(
        title: Text("Error"),
        message: Text(profilesManager.error!.localizedDescription),
        dismissButton: Alert.Button.default(Text("OK"))
      )
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

