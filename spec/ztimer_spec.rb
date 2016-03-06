require 'spec_helper'

describe Ztimer do
  let(:idler) { Lounger.new }
  let(:mutex) { Mutex.new }

  it 'has a version number' do
    expect(Ztimer::VERSION).not_to be nil
  end

  it { is_expected.to respond_to :after }
  it { is_expected.to respond_to :concurrency }
  it { is_expected.to respond_to :concurrency= }
  it { is_expected.to respond_to :running }
  it { is_expected.to respond_to :count }
  it { is_expected.to respond_to :jobs_count }

  describe '#after' do
    let(:delay) { 1 } # milliseconds

    it "should execute the block after the delay" do
      execution = 0
      Ztimer.after(delay) do
        mutex.synchronize{ execution += 1 }
      end
      sleep(delay / 1000.to_f + 0.01) # give the time to complete the job
      expect(execution).to eq(1)
    end
  end

  describe '#concurrency' do
    let(:notifications) { 100 }
    subject(:concurrency) { Ztimer.concurrency }

    it { is_expected.to eq(20) } # default

    it "should limit the maximum concurrent executions" do
      counter = 0
      maximum = 0
      notifications.times do
        Ztimer.after(10) do
          mutex.synchronize do
            counter += 1
            maximum = [maximum, Ztimer.running].max
            idler.signal if counter == notifications
          end
        end
      end
      idler.wait
      expect(maximum).to be <= Ztimer.concurrency
    end
  end

  describe '#concurrency=' do
    let(:new_concurrency) { 50 }
    subject(:concurrency) { Ztimer.concurrency }

    it "should change the value of Ztimer concurrency" do
      expect(Ztimer.concurrency).to eq(20)
      Ztimer.concurrency = new_concurrency
      expect(Ztimer.concurrency).to eq(new_concurrency)
    end
  end

  describe '#jobs_count' do
    let(:jobs)  { 100 }
    let(:delay) { 10 }

    it "should return the number of waiting notifications" do
      jobs.times do
        Ztimer.after(delay) {}
      end
      expect(Ztimer.jobs_count).to eq(jobs)
      sleep(delay / 1000.to_f + 0.01)
      expect(Ztimer.jobs_count).to eq(0)
    end
  end
end
