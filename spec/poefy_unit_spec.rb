#!/usr/bin/env ruby
# Encoding: UTF-8

################################################################################

describe Poefy::Poem, "-- Unit tests" do

  describe "#transform_input_regex" do

    # Singleton which includes the method.
    # Make the private methods public.
    let(:obj) do
      class Sing
        include Poefy::PoeticForms
        include Poefy::StringManipulation
        public *private_instance_methods
      end.new
    end

    describe "using rhyme string 'aabba'" do
      normal_input = [
        [/^T/,
          {
            1=>/^T/,
            2=>/^T/,
            3=>/^T/,
            4=>/^T/,
            5=>/^T/
          }],
        [/^T/i,
          {
            1=>/^T/i,
            2=>/^T/i,
            3=>/^T/i,
            4=>/^T/i,
            5=>/^T/i
          }],
        ['rgegerg',
          {
            1=>/rgegerg/,
            2=>/rgegerg/,
            3=>/rgegerg/,
            4=>/rgegerg/,
            5=>/rgegerg/
          }],
        ['^[^e]*$',
          {
            1=>/^[^e]*$/,
            2=>/^[^e]*$/,
            3=>/^[^e]*$/,
            4=>/^[^e]*$/,
            5=>/^[^e]*$/
          }],
        [[/a/,/b/,/c/,/d/,/e/],
          {
            1=>/a/,
            2=>/b/,
            3=>/c/,
            4=>/d/,
            5=>/e/
          }],
        [['a','b','c','d','e'],
          {
            1=>/a/,
            2=>/b/,
            3=>/c/,
            4=>/d/,
            5=>/e/
          }],
        [['a',/b/,'c',/d/,/e/],
          {
            1=>/a/,
            2=>/b/,
            3=>/c/,
            4=>/d/,
            5=>/e/
          }],
        [[/a/,/b/,/c/,/d/,/e/],
          {
            1=>/a/,
            2=>/b/,
            3=>/c/,
            4=>/d/,
            5=>/e/
          }],
        [{1=>'a', 2=>'b', 3=>'c', 4=>'d', 5=>'e'},
          {
            1=>/a/,
            2=>/b/,
            3=>/c/,
            4=>/d/,
            5=>/e/
          }],
        [{1=>/a/, 2=>/b/, 3=>/c/, 4=>/d/, 5=>/e/},
          {
            1=>/a/,
            2=>/b/,
            3=>/c/,
            4=>/d/,
            5=>/e/
          }],
        [{1=>/a/, 2=>'b', 3=>'c', 4=>/d/, 5=>/e/},
          {
            1=>/a/,
            2=>/b/,
            3=>/c/,
            4=>/d/,
            5=>/e/
          }],
        [{0=>/o/, 3=>'c', 4=>/d/},
          {
            1=>/o/,
            2=>/o/,
            3=>/c/,
            4=>/d/,
            5=>/o/
          }],
        ["['(?=^[A-Z])(?=^[^eE]*$)', '^[^eE]*$', '^[^eE]*$', '^[^eE]*$', '^[^eE]*$']",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        [['(?=^[A-Z])(?=^[^eE]*$)', '^[^eE]*$', '^[^eE]*$', '^[^eE]*$', '^[^eE]*$'],
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        ["{1: '(?=^[A-Z])(?=^[^eE]*$)', 2: '^[^eE]*$', 3: '^[^eE]*$', 4: '^[^eE]*$', 5: '^[^eE]*$'}",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        [{1=>'(?=^[A-Z])(?=^[^eE]*$)', 2=>'^[^eE]*$', 3=>'^[^eE]*$', 4=>'^[^eE]*$', 5=>'^[^eE]*$'},
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        [{1=>/(?=^[A-Z])(?=^[^eE]*$)/, 2=>'^[^eE]*$', 3=>'^[^eE]*$', 4=>/^[^eE]*$/, 5=>'^[^eE]*$'},
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        ["{0: '^[^eE]*$', 1: '(?=^[A-Z])(?=^[^eE]*$)'}",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        [{0=>'^[^eE]*$', 1=>'(?=^[A-Z])(?=^[^eE]*$)'},
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        ["{1: '(?=^[A-Z])(?=^[^eE]*$)', 2: '^[^eE]*$', 3: '^[^eE]*$', 5: '^[^eE]*$'}",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>//,
            5=>/^[^eE]*$/
          }],
        ["{1: '(?=^[A-Z])(?=^[^eE]*$)', 4: '^[^eE]*$'}",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>//,
            3=>//,
            4=>/^[^eE]*$/,
            5=>//
          }],
        ["{1: '(?=^[A-Z])(?=^[^eE]*$)', 2: '^[^eE]*$', 3: '^[^eE]*$', -1: '^[^eE]*$', -2: '^[^eE]*$'}",
          {
            1=>/(?=^[A-Z])(?=^[^eE]*$)/,
            2=>/^[^eE]*$/,
            3=>/^[^eE]*$/,
            4=>/^[^eE]*$/,
            5=>/^[^eE]*$/
          }],
        ['{7: \'^\S+$\'}',
          {
            1=>//,
            2=>//,
            3=>//,
            4=>//,
            5=>//,
            7=>/^\S+$/
          }],
        [{'3m1'=>/a/, 2=>'b', 0=>/c/},
          {
            1=>/a/,
            2=>/b/,
            3=>/c/,
            4=>/a/,
            5=>/c/
          }],
      ]
      weird_input = [
        ['x',
          { 1=>/x/,
            2=>/x/,
            3=>/x/,
            4=>/x/,
            5=>/x/
          }],
        ['xxxx',
          { 1=>/xxxx/,
            2=>/xxxx/,
            3=>/xxxx/,
            4=>/xxxx/,
            5=>/xxxx/
          }],
        ['xxxx40',
          { 1=>/xxxx40/,
            2=>/xxxx40/,
            3=>/xxxx40/,
            4=>/xxxx40/,
            5=>/xxxx40/
          }],
        ['xx40xx',
          { 1=>/xx40xx/,
            2=>/xx40xx/,
            3=>/xx40xx/,
            4=>/xx40xx/,
            5=>/xx40xx/
          }],
        ['<40xxxx></40xxxx>',
          { 1=>/<40xxxx><\/40xxxx>/,
            2=>/<40xxxx><\/40xxxx>/,
            3=>/<40xxxx><\/40xxxx>/,
            4=>/<40xxxx><\/40xxxx>/,
            5=>/<40xxxx><\/40xxxx>/
          }],
        ['{xxxxx: xxxxx}',
          {1=>//,2=>//,3=>//,4=>//,5=>//}],
        ['{2: f}',
          {1=>//,2=>/f/,3=>//,4=>//,5=>//}],
        [:foo,
          {1=>/foo/,2=>/foo/,3=>/foo/,4=>/foo/,5=>/foo/}],
        [{0=>:foo, 4=>:bar},
          {1=>/foo/,2=>/foo/,3=>/foo/,4=>/bar/,5=>/foo/}],
        [123,
          {1=>/123/,2=>/123/,3=>/123/,4=>/123/,5=>/123/}],
        [Object,
          {1=>/Object/,2=>/Object/,3=>/Object/,4=>/Object/,5=>/Object/}],
        [GC,
          {1=>/GC/,2=>/GC/,3=>/GC/,4=>/GC/,5=>/GC/}],
        [TypeError.new('foo'),
          {1=>/foo/,2=>/foo/,3=>/foo/,4=>/foo/,5=>/foo/}],
        ['{xxxxx}',
          {1=>//,2=>//,3=>//,4=>//,5=>//}],
        ['{{xxxxx}}',
          {1=>//,2=>//,3=>//,4=>//,5=>//}],
        ['{3: }',
          {1=>//,2=>//,3=>//,4=>//,5=>//}],
        ['{40}',
          {1=>//,2=>//,3=>//,4=>//,40=>//,5=>//}],
        ['{[40]}',
          {1=>//,2=>//,3=>//,4=>//,5=>//}],
        ['{{40}}',
          {1=>//,2=>//,3=>//,4=>//,5=>//}],
        ['{{}}',
          {1=>//,2=>//,3=>//,4=>//,5=>//}],
      ]
      error_input = [
        "{1: /(?=^[A-Z])(?=^[^eE]*$)/, 4: /^[^eE]*$/}",
        '{1: 12',
        '{3: 4: 5}',
        '{xxxxx: 8000, 0: xxxxx: 8000}',
      ]
      describe "normal input" do
        normal_input.each do |pair|
          it "regex: #{pair.first}" do
            rhyme = obj.tokenise_rhyme('aabba')
            out   = obj.transform_input_regex(pair.first, 'aabba')
            again = obj.transform_input_regex(out, 'aabba')
            expect(out).to eq pair.last
            expect(again).to eq out
            expect(again).to eq pair.last
          end
        end
      end
      describe "weird (but technically fine) input" do
        weird_input.each do |pair|
          it "regex: #{pair.first}" do
            rhyme = obj.tokenise_rhyme('aabba')
            out   = obj.transform_input_regex(pair.first, 'aabba')
            again = obj.transform_input_regex(out, 'aabba')
            expect(out).to eq pair.last
            expect(again).to eq out
            expect(again).to eq pair.last
          end
        end
      end
      describe "error input" do
        error_input.each do |i|
          it "regex: #{i}" do
            rhyme = obj.tokenise_rhyme('aabba')
            expect {
              obj.transform_input_regex(i, 'aabba')
            }.to raise_error(Poefy::RegexError)
          end
        end
      end
    end
  end

  ##############################################################################

  describe "#transform_input_syllable" do

    # Singleton which includes the method.
    # Make the private methods public.
    let(:obj) do
      class Sing
        include Poefy::PoeticForms
        include Poefy::StringManipulation
        public *private_instance_methods
      end.new
    end
    describe "using rhyme string 'aabba'" do
      normal_input = [
        [0,
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        [10,
          {1=>10,2=>10,3=>10,4=>10,5=>10}],
        ['0',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['10',
          {1=>10,2=>10,3=>10,4=>10,5=>10}],
        ['99',
          {1=>99,2=>99,3=>99,4=>99,5=>99}],
        ['8,9,10',
          {1=>[8,9,10],2=>[8,9,10],3=>[8,9,10],4=>[8,9,10],5=>[8,9,10]}],
        ['6,7,8,9',
          {1=>[6,7,8,9],2=>[6,7,8,9],3=>[6,7,8,9],4=>[6,7,8,9],5=>[6,7,8,9]}],
        ['[10]',
          {1=>10,2=>0,3=>0,4=>0,5=>0}],
        ['[8,8,5,5,8]',
          {1=>8,2=>8,3=>5,4=>5,5=>8}],
        ['[[8,9],[8,9],[4,5,6],[4,5,6],[8,9]]',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>[4,5,6],5=>[8,9]}],
        ['{1:8,2:8,3:5,4:5,5:8}',
          {1=>8,2=>8,3=>5,4=>5,5=>8}],
        ['{1:8,2:8,3:5,5:8}',
          {1=>8,2=>8,3=>5,4=>0,5=>8}],
        ['{0:99,1:8,2:8,3:5,5:8}',
          {1=>8,2=>8,3=>5,4=>99,5=>8}],
        ['{1:[8,9],2:[8,9],3:[4,5,6],4:[4,5,6],5:[8,9]}',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>[4,5,6],5=>[8,9]}],
        ['{1:[8,9],2:[8,9],3:[4,5,6],5:[8,9]}',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>0,5=>[8,9]}],
        ['{0:99,1:[8,9],2:[8,9],3:[4,5,6],5:[8,9]}',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>99,5=>[8,9]}],
        ['{0:[8,9],3:[4,5,6],4:[4,5,6]}',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>[4,5,6],5=>[8,9]}],
        ['{1:8,5:8}',
          {1=>8,2=>0,3=>0,4=>0,5=>8}],
        ['{1:8,2:8,3:5,-2:5,-1:8}',
          {1=>8,2=>8,3=>5,4=>5,5=>8}],
        ['{o:1,e:2}',
          {1=>1,2=>2,3=>1,4=>2,5=>1}],
        ['{o:1,0:9}',
          {1=>1,2=>9,3=>1,4=>9,5=>1}],
        ['{o:1,e:2,0:9}',
          {1=>1,2=>2,3=>1,4=>2,5=>1}],
        ['{o:8,e:6,-2:6,-1:4}',
          {1=>8,2=>6,3=>8,4=>6,5=>4}],
        ['{o:8,e:6,-2:6,-1:4,0:9}',
          {1=>8,2=>6,3=>8,4=>6,5=>4}],
        ['8-10',
          {1=>[8,9,10],2=>[8,9,10],3=>[8,9,10],4=>[8,9,10],5=>[8,9,10]}],
        ['6-9',
          {1=>[6,7,8,9],2=>[6,7,8,9],3=>[6,7,8,9],4=>[6,7,8,9],5=>[6,7,8,9]}],
        ['4-9',
          { 1=>[4,5,6,7,8,9],
            2=>[4,5,6,7,8,9],
            3=>[4,5,6,7,8,9],
            4=>[4,5,6,7,8,9],
            5=>[4,5,6,7,8,9]}],
        ['4,6,8-10,12',
          { 1=>[4,6,8,9,10,12],
            2=>[4,6,8,9,10,12],
            3=>[4,6,8,9,10,12],
            4=>[4,6,8,9,10,12],
            5=>[4,6,8,9,10,12]}],
        ['[4,6,8-10,12]',
          {1=>4,2=>6,3=>[8,9,10],4=>12,5=>0}],
        ['{e:"4,6,8-10,12"}',
          {1=>0,2=>[4,6,8,9,10,12],3=>0,4=>[4,6,8,9,10,12],5=>0}],
        ['{0:6,-1:6-10}',
          {1=>6,2=>6,3=>6,4=>6,5=>[6,7,8,9,10]}],
        ['{0:4-6,-1:6-10}',
          {1=>[4,5,6],2=>[4,5,6],3=>[4,5,6],4=>[4,5,6],5=>[6,7,8,9,10]}],
        ['{e:4-6,-1:6-10}',
          {1=>0,2=>[4,5,6],3=>0,4=>[4,5,6],5=>[6,7,8,9,10]}],
        ['[[8,9],[8,9],[4,5,6],[4,5,6],[8,9]]',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>[4,5,6],5=>[8,9]}],
        ['[[8-9],[8-9],[4-6],[4-6],[8-9]]',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>[4,5,6],5=>[8,9]}],
        ['[[8,9],[8,9],4-6,4-6,[8,9]]',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>[4,5,6],5=>[8,9]}],
        ['[8-9,8-9,4-6,4-6,8-9]',
          {1=>[8,9],2=>[8,9],3=>[4,5,6],4=>[4,5,6],5=>[8,9]}],
        ['{0:11,3m0:30}',
          {1=>11,2=>11,3=>30,4=>11,5=>11}],
        ['{0:11,3m0:30,3m1:31}',
          {1=>31,2=>11,3=>30,4=>31,5=>11}],
        [{0=>11,'3m0'=>30,'3m1'=>31},
          {1=>31,2=>11,3=>30,4=>31,5=>11}],
        [{0=>11,'3m0'=>[1,2,3,4],'3m1'=>31},
          {1=>31,2=>11,3=>[1,2,3,4],4=>31,5=>11}]
      ]
      weird_input = [
        ['40xxxx',
          {1=>40,2=>40,3=>40,4=>40,5=>40}],
        ['{3: 4 5}',
          {1=>0,2=>0,3=>4,4=>0,5=>0}],
        ['{}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['{xxxxx: 8}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['{xxxxx: 8000}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['{2m12: 9}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['{1m0: 9}',
          {1=>9,2=>9,3=>9,4=>9,5=>9}],
        ['{1m1: 9}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['{-1m0: 9}',
          {1=>9,2=>9,3=>9,4=>9,5=>9}],
        ['{-1m1: 9}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['{-1m1: -9}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['{10: 2}',
          {1=>0,2=>0,3=>0,4=>0,5=>0,10=>2}],
        ['{0:1, 0:2, 0:3, 0:4, 0:5, 0:6, 0:7, 0:8, 0:9}',
          {1=>9,2=>9,3=>9,4=>9,5=>9}],
        ['{1: -12}',
          {1=>12,2=>0,3=>0,4=>0,5=>0}],
        ['{-12: -12}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['1: 12}',
          {1=>12,2=>0,3=>0,4=>0,5=>0}],
        ['1: 12',
          {1=>1,2=>1,3=>1,4=>1,5=>1}],
        ['40    ',
          {1=>40,2=>40,3=>40,4=>40,5=>40}],
        ['    40',
          {1=>40,2=>40,3=>40,4=>40,5=>40}],
        ['{1m1: 9}    ',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['    {1m1: 9}',
          {1=>0,2=>0,3=>0,4=>0,5=>0}],
        ['[1,2,3,4,[1,2,3,4,[1,2,3,4,[1,2,3,4,[1,2,3,4,5]]]]]',
          {1=>1,2=>2,3=>3,4=>4,5=>[1,2,3,4,5]}],
        ['[1,2,3,4,[1,2,3,4,[1,2,3,4,[1,2,3,4,999,[1,2,3,4,5]]]]]',
          {1=>1,2=>2,3=>3,4=>4,5=>[1,2,3,4,5,999]}],
        [[10],
          {1=>10,2=>0,3=>0,4=>0,5=>0}],
        [[8,8,5,5,8],
          {1=>8,2=>8,3=>5,4=>5,5=>8}],
        [[1,2,3,4,[1,2,3,4,[1,2,3,4,[1,2,3,4,999,[1,2,3,4,5]]]]],
          {1=>1,2=>2,3=>3,4=>4,5=>[1,2,3,4,5,999]}],
        [3.141592653,
          {1=>3,2=>3,3=>3,4=>3,5=>3}],
        [1.618033988,
          {1=>1,2=>1,3=>1,4=>1,5=>1}]
      ]
      error_input = [
        'x',
        'xxxx',
        'xxxx40',
        'xx40xx',
        '<40xxxx></40xxxx>',
        '{1: 12',
        '{xxxxx}',
        '{{xxxxx}}',
        '{xxxxx: xxxxx}',
        '{2: f}',
        '{3: }',
        '{3: 4: 5}',
        '{xxxxx: 8000, 0: xxxxx: 8000}',
        '{40}',
        '{[40]}',
        '{{40}}',
        '{{}}',
        :sausage,
        /^the/,
        Object,
        GC,
        TypeError.new('foo')
      ]
      describe "normal input" do
        normal_input.each do |pair|
          it "syllable: #{pair.first}" do
            rhyme = obj.tokenise_rhyme('aabba')
            out   = obj.transform_input_syllable(pair.first, 'aabba')
            again = obj.transform_input_syllable(out, 'aabba')
            expect(out).to eq pair.last
            expect(again).to eq out
            expect(again).to eq pair.last
          end
        end
      end
      describe "weird (but technically fine) input" do
        weird_input.each do |pair|
          it "syllable: #{pair.first}" do
            rhyme = obj.tokenise_rhyme('aabba')
            out   = obj.transform_input_syllable(pair.first, 'aabba')
            again = obj.transform_input_syllable(out, 'aabba')
            expect(out).to eq pair.last
            expect(again).to eq out
            expect(again).to eq pair.last
          end
        end
      end
      describe "error input" do
        error_input.each do |i|
          it "syllable: #{i}" do
            rhyme = obj.tokenise_rhyme('aabba')
            expect {
              obj.transform_input_syllable(i, 'aabba')
            }.to raise_error(Poefy::SyllableError)
          end
        end
      end
    end
  end

  ##############################################################################

  describe "private method #poetic_form_from_text" do

    # Singleton which includes the method.
    # Make the private methods public.
    let(:obj) do
      class Sing
        include Poefy::PoeticFormFromText
        include Poefy::StringManipulation
        public *private_instance_methods
      end.new
    end

    it "'80' should rhyme with 'weighty'" do
      lines = ["Lorem ipsum dolor weighty", "Lorem ipsum dolor 80"]
      form = obj.poetic_form_from_text(lines)
      expect(form[:rhyme].uniq.count).to be 1
    end
    it "'80' should not rhyme with 'shoe'" do
      lines = ["Lorem ipsum dolor shoe", "Lorem ipsum dolor 80"]
      form = obj.poetic_form_from_text(lines)
      expect(form[:rhyme].uniq.count).to_not be 1
    end
    it "'2' should rhyme with 'shoe'" do
      lines = ["Lorem ipsum dolor shoe", "Lorem ipsum dolor 2"]
      form = obj.poetic_form_from_text(lines)
      expect(form[:rhyme].uniq.count).to be 1
    end
    it "'2' should not rhyme with 'weighty'" do
      lines = ["Lorem ipsum dolor weighty", "Lorem ipsum dolor 2"]
      form = obj.poetic_form_from_text(lines)
      expect(form[:rhyme].uniq.count).to_not be 1
    end
    it "'wind' should rhyme with 'sinned'" do
      lines = ["A mighty wind", "A whitey sinned"]
      form = obj.poetic_form_from_text(lines)
      expect(form[:rhyme].uniq.count).to be 1
    end
    it "'wind' should rhyme with 'mind'" do
      lines = ["A mighty wind", "A flighty mind"]
      form = obj.poetic_form_from_text(lines)
      expect(form[:rhyme].uniq.count).to be 1
    end
    it "'wind' should not rhyme with 'drunk'" do
      lines = ["A mighty wind", "A fighty drunk"]
      form = obj.poetic_form_from_text(lines)
      expect(form[:rhyme].uniq.count).to_not be 1
    end
  end

end

################################################################################
