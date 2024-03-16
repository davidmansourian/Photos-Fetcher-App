Simple photos fetcher app in SwiftUI with focus on best practices developed for a Bachelor's thesis project

This photos fetcher app loads the same image list from an external API everytime. Images are therefore saved to disk and loaded from device before shown in view. The desired behavior for image loading is to load all images before showing any of them in the view.

Saving the images to disk for future use saves approximately 22 MB of network data on each launch of the app. Loading the images from disk also saves approximately 40 MB of memory usage.
