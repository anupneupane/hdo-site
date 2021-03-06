require 'spec_helper'

describe District do
  let(:valid_district) { District.make! }

  it "should have a unique name" do
    invalid = District.make(:name => valid_district.name)
    invalid.should_not be_valid
  end

  it "should have a unique external id" do
    invalid = District.make!
    invalid.external_id = valid_district.external_id

    invalid.should_not be_valid
  end

  it 'can add representatives' do
    valid_district.representatives << Representative.make!
    valid_district.representatives.size.should == 1
  end

  it "won't add the same representative twice" do
    representative = Representative.make!

    valid_district.representatives << representative
    valid_district.representatives << representative

    valid_district.representatives.size.should == 1
  end

end
