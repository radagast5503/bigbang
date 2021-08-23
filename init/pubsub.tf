resource "google_pubsub_topic" "image_dropbox" {
    name = "image-dropbox"
    labels = {
        team = "radagast5503"
    }
    project = google_project.main.project_id
}