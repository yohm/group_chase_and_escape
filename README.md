group chase and escape (鬼ごっこ)
======================

## Group Chase and Escape

集団鬼ごっこのシミュレーション

- 鬼は逃亡者を捕まえようと、逃亡者は鬼から逃げようとする。
  - 鬼、逃亡者のアルゴリズムを変えて遊んでみよう。

## 実行方法

３種類の鬼ごっこ実行システムがあります。

- GUIでの実行 ("battle\_stage\_gui.rb")
  - 鬼・逃亡者それぞれ１種類のロジックを指定して対決させます。
  - 鬼ごっこの様子が可視化されて表示されるので、何が起きているか直感的に把握できます。
  - 実行にはruby-processingが必要です。
- CUIでの実行 ("battle\_stage.rb")
  - GUIと同様に１種類のロジックを指定して対決させます。
  - GUIとは異なり可視化はされませんが実行速度が速いです。
  - ruby-processingがなくても使えます。
- 複数の鬼、逃亡者の戦略の総当たり戦での対決 ("round\_robin.rb")
  - 複数の鬼・逃亡者のロジックを準備し、それらを総当たりで対決させるときに使用します。

手順としては鬼・逃亡者のロジックを実装して、上記３種類の鬼ごっこシステムを実行することになります。

鬼・逃亡者のロジックは "ChaserStrategy", "EscapeeStrategy" クラスに実装します。
（詳細は後ほど。）

### GUIでの実行

- GUIで実行すると鬼ごっこの様子を視覚的に分かりやすく見ることができます。
- ruby-processingのインストールが必要なので、こちらを見てインストールしてください。
  - [Ruby-Processingのインストール方法](http://qiita.com/yohm/items/f3f82f423b507cec1dcc)
- 実行コマンドは以下の通りです。
  ```
  rp5 run battle_stage_gui.rb -c chaser_strategy.rb -e escapee_strategy.rb -r 1234
  ```
  - -c オプションに ChaesrStrategy, -e オプションに EscapeeStrategy を実装したスクリプトへのパスを与えてください。
    - 指定がない場合はデフォルトのロジックを使います。
  - -r オプションに乱数の種を指定してください。指定がない場合はランダムな値を使います。

### CUIでの実行

- GUIとほとんど同じように実行できます。
  - しかしこちらは可視化を行わないので、ruby-processingがなくても動作しますし高速です。
- 実行コマンドは以下の通りです。
  ```
  ruby battle_stage.rb -c chaser_strategy.rb -e escapee_strategy.rb -r 1234
  ```
  - -c オプションに ChaesrStrategy, -e オプションに EscapeeStrategy を実装したスクリプトへのパスを与えてください。
    - 指定がない場合はデフォルトのロジックを使います。
  - -r オプションに乱数の種を指定してください。指定がない場合はランダムな値を使います。

### 総当たり戦の実行

- 複数の鬼や逃亡者を作って対決させてたいとき、総当たり戦を行うことができます。
- まず ChaserStrategy, EscapeeStrategy クラスを実装したスクリプトを "round\_robin\_stage/chaser\_strategies/", "round\_robin\_stage/escapee\_strategies/" のディレクトリに置いてください。
  - ファイル名は重複してはいけないので、"chaser1.rb", "randomchaser.rb" など適当な名前にしておいてください。
    - ディレクトリ以下の拡張子が".rb"のファイルを全て検索して、鬼・逃亡者として登録されます。
- 実行コマンドは以下の通りです。
  ```
  ruby round_robin_stage/round_robin_stage.rb
  ```
- 鬼・逃亡者の組み合わせの数だけ対決が実施されます。
  - さらに各対決で乱数を変えて複数回実行し、全員が捕まるまでの平均時刻を出力します。


## 鬼・逃亡者のロジックの実装

- 鬼は ChaserStrategy クラスを実装します。
  - 以下のサンプルの様に `#next_direction` メソッドを実装します。

```rb:sample_chaser.rb
class ChaserStrategy

  def initialize
  end

  def next_direction(chaser_positions, escapee_positions)
    return [0,0] if escapee_positions.empty?
    dx, dy = escapee_positions.first
    candidate = []
    if dx > 0
      candidate.push [1,0]
    elsif dx < 0
      candidate.push [-1,0]
    end
    if dy > 0
      candidate.push [0,1]
    elsif dy < 0
      candidate.push [0,-1]
    end
    candidate.sample
  end
end
```

- メソッドの引数には、自分以外の鬼と逃亡者の相対位置が与えられます。
  - 例えば、自分から見て右上と左下の場所にいるとすると、`[ [1,1], [-1,-1] ]` という配列の配列として与えれます。
  - 引数で与えられる配列は自分からの距離が近い順にソートした状態で渡されます。
  - 場内にいる鬼、逃亡者の位置がわかるので、この情報をもとに自分が動く方向を決めてください。
- メソッドの返り値は、自分の動きたい方向を配列で返します。
  - 例えば右に動きたい場合は [1,0] を返します。上に動きたい場合は [0,1] を返します。
  - ２マス以上の距離を移動することはできません。例えば[0,2]を返すことはできません。返すと例外が発生して終了します。
- もし必要であれば、インスタンス変数を使っても構いません。
  - インスタンス変数を使えば自分の状態を覚えておくことができます。
  - 各鬼、逃亡者ごとにStrategyクラスは作られます。

