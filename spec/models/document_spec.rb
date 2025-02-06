require "rails_helper"

RSpec.describe Document, type: :model do
  it { should belong_to(:site) }
  it { should have_many(:workflow_histories).class_name("DocumentWorkflowHistory") }

  it { should validate_presence_of(:file_name) }
  it { should validate_presence_of(:url) }
  it { should allow_value("http://example.com").for(:url) }
  it { should_not allow_value("invalid-url").for(:url) }

  it { should validate_presence_of(:document_status) }
  it { should validate_inclusion_of(:document_status).in_array(%w[discovered downloaded]) }

  it { should validate_presence_of(:classification_status) }
  it { should validate_inclusion_of(:classification_status).in_array(%w[pending auto_classified classified reclassified]) }

  it { should validate_presence_of(:policy_review_status) }
  it { should validate_inclusion_of(:policy_review_status).in_array(%w[pending auto_reviewed reviewed rereviewed]) }

  it { should validate_presence_of(:recommendation_status) }
  it { should validate_inclusion_of(:recommendation_status).in_array(%w[pending auto_recommendation recommendation_adjusted recommended]) }

  describe "S3 storage" do
    let(:site) { create(:site, primary_url: "https://www.city.org") }
    let(:document) { create(:document, site: site) }

    describe "#s3_path" do
      it "generates correct path using site prefix and document id" do
        expect(document.s3_path).to eq("www-city-org/#{document.id}/document.pdf")
      end
    end

    describe "versioning", :aws do
      let(:s3_client) { Aws::S3::Client.new(stub_responses: true) }
      let(:s3_resource) { Aws::S3::Resource.new(client: s3_client) }

      before do
        allow(Aws::S3::Resource).to receive(:new).and_return(s3_resource)
      end

      before do
        allow(Rails.application.config.active_storage).to receive(:service_configurations)
          .and_return({
            Rails.env.to_s => {
              "service" => "S3",
              "access_key_id" => "test",
              "secret_access_key" => "test",
              "region" => "us-east-1",
              "bucket" => "test-bucket",
              "endpoint" => "http://localhost:4566",
              "force_path_style" => true
            }
          })
      end

      describe "#file_versions" do
        it "returns list of versions" do
          versions = [
            double("version1", version_id: "v1", last_modified: Time.current, size: 1000, etag: "abc"),
            double("version2", version_id: "v2", last_modified: 1.day.ago, size: 900, etag: "def")
          ]

          allow_any_instance_of(Aws::S3::Bucket).to receive(:object_versions)
            .with(prefix: document.s3_path)
            .and_return(versions)

          expect(document.file_versions.count).to eq(2)
        end
      end

      describe "#latest_file" do
        it "returns the most recent version" do
          latest = double("latest_version", version_id: "v1", last_modified: Time.current)
          older = double("older_version", version_id: "v2", last_modified: 1.day.ago)

          allow_any_instance_of(Aws::S3::Bucket).to receive(:object_versions)
            .with(prefix: document.s3_path)
            .and_return([latest, older])

          expect(document.latest_file).to eq(latest)
        end
      end

      describe "#file_version" do
        it "gets specific version by id" do
          version = double("version")
          allow_any_instance_of(Aws::S3::Object).to receive(:get)
            .with(version_id: "v1")
            .and_return(version)

          expect(document.file_version("v1")).to eq(version)
        end
      end

      describe "#version_metadata" do
        it "returns formatted version metadata" do
          time = Time.current
          version = double(
            "version",
            version_id: "v1",
            last_modified: time,
            size: 1000,
            etag: "abc123"
          )

          metadata = document.version_metadata(version)

          expect(metadata).to include(
            version_id: "v1",
            last_modified: time,
            size: 1000,
            etag: "abc123"
          )
        end
      end
    end
  end

  describe "workflow" do
    let(:site) { create(:site) }
    let(:document) { create(:document, site: site, document_status: "discovered", classification_status: "pending", policy_review_status: "pending", recommendation_status: "pending") }

    context "document status transitions" do
      it "follows the document status workflow" do
        expect { document.download }.to change(document, :document_status)
          .from("discovered").to("downloaded")
      end

      it "prevents invalid transitions" do
        document.download! # First transition
        expect { document.download! }.to raise_error(StateMachines::InvalidTransition)
      end
    end

    context "classification status transitions" do
      before do
        document.update!(document_status: "downloaded")
      end

      it "follows the complete classification workflow" do
        expect {
          document.complete_classification(
            category: "permit",
            confidence: 0.95
          )
        }.to change(document, :classification_status)
          .from("pending").to("auto_classified")
          .and change(document, :recommended_category).to("permit")
          .and change(document, :category_confidence).to(0.95)
      end

      it "follows the approve classification workflow" do
        document.complete_classification!(category: "permit", confidence: 0.95)
        expect { document.approve_classification }.to change(document, :classification_status)
          .from("auto_classified").to("classified")
          .and change(document, :approved_category).to("permit")
      end

      it "follows the change classification workflow" do
        document.complete_classification!(category: "permit", confidence: 0.95)
        expect {
          document.change_classification(new_category: "application")
        }.to change(document, :classification_status)
          .from("auto_classified").to("reclassified")
          .and change(document, :changed_category).to("application")
      end

      it "prevents invalid transitions" do
        expect { document.approve_classification! }.to raise_error(StateMachines::InvalidTransition)
        expect { document.change_classification!(new_category: "application") }.to raise_error(StateMachines::InvalidTransition)
      end
    end

    context "policy review status transitions" do
      before do
        document.update!(classification_status: "classified")
      end

      it "follows the complete policy review workflow" do
        expect {
          document.complete_policy_review(
            action: "ocr_needed",
            confidence: 0.88
          )
        }.to change(document, :policy_review_status)
          .from("pending").to("auto_reviewed")
          .and change(document, :recommended_accessibility_action).to("ocr_needed")
          .and change(document, :accessibility_confidence).to(0.88)
      end

      it "follows the approve policy workflow" do
        document.complete_policy_review!(action: "ocr_needed", confidence: 0.88)
        expect { document.approve_policy }.to change(document, :policy_review_status)
          .from("auto_reviewed").to("reviewed")
          .and change(document, :approved_accessibility_action).to("ocr_needed")
      end

      it "follows the change policy workflow" do
        document.complete_policy_review!(action: "ocr_needed", confidence: 0.88)
        expect {
          document.change_policy(new_action: "manual_review")
        }.to change(document, :policy_review_status)
          .from("auto_reviewed").to("rereviewed")
          .and change(document, :changed_accessibility_action).to("manual_review")
      end

      it "prevents invalid transitions" do
        expect { document.approve_policy! }.to raise_error(StateMachines::InvalidTransition)
        expect { document.change_policy!(new_action: "manual_review") }.to raise_error(StateMachines::InvalidTransition)
      end
    end

    context "recommendation status transitions" do
      before do
        document.update!(policy_review_status: "reviewed")
      end

      it "follows the complete recommendation workflow" do
        expect { document.complete_recommendation }.to change(document, :recommendation_status)
          .from("pending").to("auto_recommendation")
      end

      it "follows the change recommendation workflow" do
        document.complete_recommendation!
        expect { document.change_recommendation }.to change(document, :recommendation_status)
          .from("auto_recommendation").to("recommendation_adjusted")
      end

      it "allows approve recommendation from auto_recommendation" do
        document.complete_recommendation!
        expect { document.approve_recommendation }.to change(document, :recommendation_status)
          .from("auto_recommendation").to("recommended")
      end

      it "allows approve recommendation from recommendation_adjusted" do
        document.complete_recommendation!
        document.change_recommendation!
        expect { document.approve_recommendation }.to change(document, :recommendation_status)
          .from("recommendation_adjusted").to("recommended")
      end

      it "prevents invalid transitions" do
        expect { document.approve_recommendation! }.to raise_error(StateMachines::InvalidTransition)
        expect { document.change_recommendation! }.to raise_error(StateMachines::InvalidTransition)
      end
    end

    context "workflow history" do
      describe "document status transitions" do
        it "records document download history" do
          expect {
            document.download!
          }.to change(DocumentWorkflowHistory, :count).by(1)

          history = document.workflow_histories.last
          expect(history.status_type).to eq("document_status")
          expect(history.from_status).to eq("discovered")
          expect(history.to_status).to eq("downloaded")
          expect(history.action_type).to eq("download")
          expect(history.metadata).to eq({})
        end
      end

      describe "classification transitions" do
        before do
          document.update!(document_status: "downloaded")
        end

        it "records complete classification history with metadata" do
          expect {
            document.complete_classification!(category: "permit", confidence: 0.95)
          }.to change(DocumentWorkflowHistory, :count).by(1)

          history = document.workflow_histories.last
          expect(history.status_type).to eq("classification_status")
          expect(history.from_status).to eq("pending")
          expect(history.to_status).to eq("auto_classified")
          expect(history.action_type).to eq("complete_classification")
          expect(history.metadata).to include(
            "category" => "permit",
            "confidence" => 0.95
          )
        end

        it "records approve classification history" do
          document.complete_classification!(category: "permit", confidence: 0.95)
          expect {
            document.approve_classification!
          }.to change(DocumentWorkflowHistory, :count).by(1)

          history = document.workflow_histories.last
          expect(history.status_type).to eq("classification_status")
          expect(history.from_status).to eq("auto_classified")
          expect(history.to_status).to eq("classified")
          expect(history.action_type).to eq("approve_classification")
          expect(history.metadata).to eq({})
        end

        it "records change classification history with metadata" do
          document.complete_classification!(category: "permit", confidence: 0.95)
          expect {
            document.change_classification!(new_category: "application")
          }.to change(DocumentWorkflowHistory, :count).by(1)

          history = document.workflow_histories.last
          expect(history.status_type).to eq("classification_status")
          expect(history.from_status).to eq("auto_classified")
          expect(history.to_status).to eq("reclassified")
          expect(history.action_type).to eq("change_classification")
          expect(history.metadata).to include(
            "new_category" => "application"
          )
        end
      end

      describe "policy review transitions" do
        before do
          document.update!(classification_status: "classified")
        end

        it "records complete policy review history with metadata" do
          expect {
            document.complete_policy_review!(action: "ocr_needed", confidence: 0.88)
          }.to change(DocumentWorkflowHistory, :count).by(1)

          history = document.workflow_histories.last
          expect(history.status_type).to eq("policy_review_status")
          expect(history.from_status).to eq("pending")
          expect(history.to_status).to eq("auto_reviewed")
          expect(history.action_type).to eq("complete_policy_review")
          expect(history.metadata).to include(
            "action" => "ocr_needed",
            "confidence" => 0.88
          )
        end

        it "records approve policy history" do
          document.complete_policy_review!(action: "ocr_needed", confidence: 0.88)
          expect {
            document.approve_policy!
          }.to change(DocumentWorkflowHistory, :count).by(1)

          history = document.workflow_histories.last
          expect(history.status_type).to eq("policy_review_status")
          expect(history.from_status).to eq("auto_reviewed")
          expect(history.to_status).to eq("reviewed")
          expect(history.action_type).to eq("approve_policy")
          expect(history.metadata).to eq({})
        end

        it "records change policy history with metadata" do
          document.complete_policy_review!(action: "ocr_needed", confidence: 0.88)
          expect {
            document.change_policy!(new_action: "manual_review")
          }.to change(DocumentWorkflowHistory, :count).by(1)

          history = document.workflow_histories.last
          expect(history.status_type).to eq("policy_review_status")
          expect(history.from_status).to eq("auto_reviewed")
          expect(history.to_status).to eq("rereviewed")
          expect(history.action_type).to eq("change_policy")
          expect(history.metadata).to include(
            "new_action" => "manual_review"
          )
        end
      end

      describe "recommendation transitions" do
        before do
          document.update!(policy_review_status: "reviewed")
        end

        it "records complete recommendation history" do
          expect {
            document.complete_recommendation!
          }.to change(DocumentWorkflowHistory, :count).by(1)

          history = document.workflow_histories.last
          expect(history.status_type).to eq("recommendation_status")
          expect(history.from_status).to eq("pending")
          expect(history.to_status).to eq("auto_recommendation")
          expect(history.action_type).to eq("complete_recommendation")
          expect(history.metadata).to eq({})
        end

        it "records change recommendation history" do
          document.complete_recommendation!
          expect {
            document.change_recommendation!
          }.to change(DocumentWorkflowHistory, :count).by(1)

          history = document.workflow_histories.last
          expect(history.status_type).to eq("recommendation_status")
          expect(history.from_status).to eq("auto_recommendation")
          expect(history.to_status).to eq("recommendation_adjusted")
          expect(history.action_type).to eq("change_recommendation")
          expect(history.metadata).to eq({})
        end

        it "records approve recommendation history" do
          document.complete_recommendation!
          document.change_recommendation!
          expect {
            document.approve_recommendation!
          }.to change(DocumentWorkflowHistory, :count).by(1)

          history = document.workflow_histories.last
          expect(history.status_type).to eq("recommendation_status")
          expect(history.from_status).to eq("recommendation_adjusted")
          expect(history.to_status).to eq("recommended")
          expect(history.action_type).to eq("approve_recommendation")
          expect(history.metadata).to eq({})
        end
      end

      it "records user in history when provided" do
        user = create(:user)
        site = create(:site, user: user)
        document = create(:document, site: site)

        document.download!
        expect(document.workflow_histories.count).to eq(1)

        history = document.workflow_histories.last
        expect(history.user).to eq(user)
        expect(history.status_type).to eq("document_status")
        expect(history.from_status).to eq("discovered")
        expect(history.to_status).to eq("downloaded")
        expect(history.action_type).to eq("download")
      end
    end

    context "alternative paths" do
      it "allows classification changes" do
        document.complete_classification!(category: "permit", confidence: 0.95)
        expect {
          document.change_classification(new_category: "application")
        }.to change(document, :classification_status)
          .from("auto_classified").to("reclassified")
          .and change(document, :changed_category).to("application")
      end

      it "allows policy action changes" do
        document.complete_policy_review!(action: "ocr_needed", confidence: 0.88)
        expect {
          document.change_policy(new_action: "manual_review")
        }.to change(document, :policy_review_status)
          .from("auto_reviewed").to("rereviewed")
          .and change(document, :changed_accessibility_action).to("manual_review")
      end
    end
  end
end
