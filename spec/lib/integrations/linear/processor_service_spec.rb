require 'rails_helper'

describe Integrations::Linear::ProcessorService do
  let(:account) { create(:account) }
  let(:api_key) { 'valid_api_key' }
  let(:linear_client) { instance_double(Linear) }
  let(:service) { described_class.new(account: account) }

  before do
    create(:integrations_hook, :linear, account: account)
    allow(Linear).to receive(:new).and_return(linear_client)
  end

  describe '#teams' do
    context 'when Linear client returns valid data' do
      let(:teams_response) do
        { 'teams' => { 'nodes' => [{ 'id' => 'team1', 'name' => 'Team One' }] } }
      end

      it 'returns parsed team data' do
        allow(linear_client).to receive(:teams).and_return(teams_response)
        result = service.teams
        expect(result).to contain_exactly({ 'id' => 'team1', 'name' => 'Team One' })
      end
    end

    context 'when Linear client returns an error' do
      let(:error_response) { { error: 'Some error message' } }

      it 'returns the error' do
        allow(linear_client).to receive(:teams).and_return(error_response)
        result = service.teams
        expect(result).to eq(error_response)
      end
    end
  end

  describe '#team_entites' do
    let(:team_id) { 'team1' }
    let(:entities_response) do
      {
        'users' => { 'nodes' => [{ 'id' => 'user1', 'name' => 'User One' }] },
        'projects' => { 'nodes' => [{ 'id' => 'project1', 'name' => 'Project One' }] },
        'workflowStates' => { 'nodes' => [] },
        'issueLabels' => { 'nodes' => [{ 'id' => 'bug', 'name' => 'Bug' }] }
      }
    end

    context 'when Linear client returns valid data' do
      it 'returns parsed entity data' do
        allow(linear_client).to receive(:team_entites).with(team_id).and_return(entities_response)
        result = service.team_entites(team_id)
        expect(result).to have_key(:users)
        expect(result).to have_key(:projects)
        expect(result).to have_key(:states)
        expect(result).to have_key(:labels)
      end
    end

    context 'when Linear client returns an error' do
      let(:error_response) { { error: 'Some error message' } }

      it 'returns the error' do
        allow(linear_client).to receive(:team_entites).with(team_id).and_return(error_response)
        result = service.team_entites(team_id)
        expect(result).to eq(error_response)
      end
    end
  end

  describe '#create_issue' do
    let(:params) do
      {
        title: 'Issue title',
        team_id: 'team1',
        description: 'Issue description',
        assignee_id: 'user1',
        priority: 2,
        label_ids: %w[bug]
      }
    end
    let(:issue_response) do
      {
        'issueCreate' => { 'issue' => { 'id' => 'issue1', 'title' => 'Issue title' } }
      }
    end

    context 'when Linear client returns valid data' do
      it 'returns parsed issue data' do
        allow(linear_client).to receive(:create_issue).with(params).and_return(issue_response)
        result = service.create_issue(params)
        expect(result).to eq({ id: 'issue1', title: 'Issue title' })
      end
    end

    context 'when Linear client returns an error' do
      let(:error_response) { { error: 'Some error message' } }

      it 'returns the error' do
        allow(linear_client).to receive(:create_issue).with(params).and_return(error_response)
        result = service.create_issue(params)
        expect(result).to eq(error_response)
      end
    end
  end

  describe '#link_issue' do
    let(:link) { 'https://example.com' }
    let(:issue_id) { 'issue1' }
    let(:link_issue_response) { { id: issue_id, link: link, 'attachmentLinkURL': { 'attachment': { 'id': 'attachment1' } } } }
    let(:link_response) { { id: issue_id, link: link, link_id: 'attachment1' } }

    context 'when Linear client returns valid data' do
      it 'returns parsed link data' do
        allow(linear_client).to receive(:link_issue).with(link, issue_id).and_return(link_issue_response)
        result = service.link_issue(link, issue_id)
        expect(result).to eq(link_response)
      end
    end

    context 'when Linear client returns an error' do
      let(:error_response) { { error: 'Some error message' } }

      it 'returns the error' do
        allow(linear_client).to receive(:link_issue).with(link, issue_id).and_return(error_response)
        result = service.link_issue(link, issue_id)
        expect(result).to eq(error_response)
      end
    end
  end
end
