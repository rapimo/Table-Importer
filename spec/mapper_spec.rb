
require 'spec_helper.rb'

describe "TableImporter::Mapper" do
  describe "a Simple Hash" do
    before :each do
      @dict = {"Contact" =>{:first_name=>:col1}}
      @mapper = TableImporter::Mapper.new(@dict)

    end
    it "should return an Array of Classes" do
      @mapper.klasses.keys.should == ["Contact"]
    end

    it "should return a Hash of attributes" do
      hash = @mapper.get_attributes_for_class("Contact",{:first_name => :col1})
      hash.should == {:attributes=>{:first_name => :col1}}
    end

    it "should return attributes for klasses" do
      @mapper.klasses["Contact"][:attributes].should == {:first_name => :col1}
    end
  end

  describe "different Column Names" do
    before :each do
      @mapper = TableImporter::Mapper.new({})
    end
      it "should assign col1 to 0" do
        @mapper.get_column_number(:col1).should == 0
      end
      it "should assign col_1 to 0" do
        @mapper.get_column_number(:col_1).should == 0
      end
    it "should assign colA to 0" do
        @mapper.get_column_number(:colA).should == 0
    end
    it "should assign col_A to 0" do
        @mapper.get_column_number(:col_A).should == 0
    end

    it "should assign col_AB to 25" do
        @mapper.get_column_number(:col_AB).should == 27
    end
    it "should assign col_ab to 25" do
        @mapper.get_column_number(:col_ab).should == 27
    end
    it "should assign col_aB to 25" do
        @mapper.get_column_number(:col_aB).should == 27
    end

    it "should assign col_27 to 26" do
        @mapper.get_column_number(:col_27).should == 26
    end
  end
  describe "Reflections" do
    before :each do
      address =Reflection.new(:has_one,"Address")
      user =Reflection.new(:belongs_to,"User")
      tags =Reflection.new(:has_many,"Tag")
      reflections = {:address=>address,:user=>user,:tags=>tags}
      Contact.stub(:reflections).and_return(reflections)
      
      @dict = {"Contact" =>{:first_name=>:col1,:address => {:street=>:col2,:zip=>:col3,:city=>:col4}}}
      @dict["Contact"].merge({:user => {:first_name=>:col5},:tags=>{:tagging=>[:col6,:col7,:col8]}})
      @mapper = TableImporter::Mapper.new(@dict)

    end
        it "should return an Array of Classes" do
      @mapper.klasses.keys.should == ["Contact"]
    end
    
    it "should return reflections hash " do

      hash = @mapper.get_attributes_for_class("Contact",{:first_name => :col1,:address=>{:street=>:col2},:user=>{:first_name=>:col5}})
      hash[:reflections].should == {:address=> {
                                      :attributes=>{:street=>:col2},
                                      :macro=>:has_one,
                                      :class_name=>"Address"},
                                    :user=>{
                                      :attributes=>{:first_name=>:col5},
                                      :macro=>:belongs_to,
                                      :class_name=>"User"}
                                    }
    end
  end

end