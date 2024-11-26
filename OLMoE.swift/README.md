# OLMoE Swift

## Requirements

- Xcode 15.4+
- iOS 17+

## Configuration

1. Rename `BuildConfig/release.example.xcconfig` to `release.xcconfig`.

2. Go to One Password, in the vault "Allen Institute" search for "AWS Gateway API Key" and "AWS Lambda Endpoint - Prod", copy and paste them in the newly renamed file

    ```plaintext
    API_KEY=your_api_key_here
    API_URL=api_url
    ```

3. Open the project in Xcode.

4. Select the project in the Project Navigator.

5. Go to Info -> Select Project OLMoE Swift

    ![config 1](https://github.com/user-attachments/assets/2a1d2404-60fa-4f0c-ac68-198273afd8c4)

6. In configurations set Debug and Release to use release.xcconfig

    ![config 2](https://github.com/user-attachments/assets/6ca124c1-0a7c-42f4-b922-50ef5c9e2924)
