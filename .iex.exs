require Cldr
require MyApp.Cldr

alias Cldr.PersonName
import Cldr.LanguageTag.Sigil, only: :macros

{:ok, en_aq} = Cldr.validate_locale("en-AQ", MyApp.Cldr)
{:ok, ja_aq} = Cldr.validate_locale("ja-AQ", MyApp.Cldr)
{:ok, fr_aq} = Cldr.validate_locale("fr-AQ", MyApp.Cldr)
{:ok, de_aq} = Cldr.validate_locale("de-AQ", MyApp.Cldr)
{:ok, ko_aq} = Cldr.validate_locale("ko-AQ", MyApp.Cldr)
{:ok, es_aq} = Cldr.validate_locale("es-AQ", MyApp.Cldr)
{:ok, pt_aq} = Cldr.validate_locale("pt-AQ", MyApp.Cldr)
{:ok, ja_aq} = Cldr.validate_locale("ja-AQ", MyApp.Cldr)
{:ok, he_aq} = Cldr.validate_locale("he-AQ", MyApp.Cldr)
{:ok, zh_aq} = Cldr.validate_locale("zh-AQ", MyApp.Cldr)
{:ok, cs_aq} = Cldr.validate_locale("cs-AQ", MyApp.Cldr)
{:ok, id_aq} = Cldr.validate_locale("id-AQ", MyApp.Cldr)
{:ok, ca_aq} = Cldr.validate_locale("ca-AQ", MyApp.Cldr)

{:ok, es_mx} = Cldr.validate_locale("es-MX", MyApp.Cldr)
{:ok, es_us} = Cldr.validate_locale("es-US", MyApp.Cldr)
{:ok, de} = Cldr.validate_locale("de", MyApp.Cldr)

# name ; given; Mary Sue
# name ; given2; Hamish
# name ; surname; Watson
# name ; locale; en_AQ

mary = %PersonName{
  given_name: "Mary Sue",
  other_given_names: "Hamish",
  surname: "Watson",
  locale: en_aq
}

# name ; given; Käthe
# name ; surname; Müller
# name ; locale; ja_AQ

kathe = %PersonName{
  given_name: "Käthe",
  surname: "Müller",
  locale: ja_aq
}

# name ; given; Irene
# name ; surname; Adler
# name ; locale; en_AQ

irene = %PersonName{
  given_name: "Irene",
  surname: "Adler",
  locale: en_aq
}

# name ; given; Sinbad
# name ; locale; ja_AQ

sinbad = %PersonName{
  given_name: "Sinbad",
  locale: ja_aq
}

# nativeG
# name ; given; Zendaya
# name ; locale; en_AQ

zendaya = %PersonName{
  given_name: "Zendaya",
  locale: en_aq
}

# nativeFull
# name ; title; M.
# name ; given; Jean-Nicolas
# name ; given-informal; Nico
# name ; given2; Louis Marcel
# name ; surname-prefix; de
# name ; surname-core; Bouchart
# name ; generation; fils
# name ; locale; fr_AQ

jn = %PersonName{
  given_name: "Jean-Nicolas",
  informal_given_name: "Nico",
  other_given_names: "Louis Marcel",
  surname_prefix: "de",
  surname: "Bouchart",
  generation: "fils",
  locale: fr_aq
}

# nativeG
# name ; given; Adèle
# name ; locale; fr_AQ

adele = %PersonName{
  given_name: "Adèle",
  locale: fr_aq
}

# nativeG
# name ; given; Iris
# name l surnameL Falke
# name ; locale; de

iris = %PersonName{
  given_name: "Iris",
  surname: "Falke",
  locale: de
}

# nativeFull
# name ; title; Dr.
# name ; given; Paul
# name ; given-informal; Pauli
# name ; given2; Vinzent
# name ; surname-prefix; von
# name ; surname-core; Fischer
# name ; generation; jr.
# name ; credentials; MdB
# name ; locale; de_AQ

paul = %PersonName{
  title: "Dr.",
  given_name: "Paul",
  informal_given_name: "Pauli",
  other_given_names: "Vinzent",
  surname_prefix: "von",
  surname: "Fischer",
  generation: "jr.",
  credentials: "MdB",
  locale: de_aq
}

# foreignGS
# name ; given; Adélaïde
# name ; surname; Lemaître
# name ; locale; ko_AQ

adelaide = %PersonName{
  given_name: "Adélaïde",
  surname: "Lemaître",
  locale: ko_aq
}

# nativeFull
# name ; title; Sr.
# name ; given; Miguel Ángel
# name ; given-informal; Migue
# name ; given2; Juan Antonio
# name ; surname-core; Pablo
# name ; surname2; Pérez
# name ; generation; II
# name ; locale; es_AQ

pablo = %PersonName{
  title: "Sr.",
  given_name: "Miguel Ángel",
  informal_given_name: "Migue",
  other_given_names: "Juan Antonio",
  surname: "Pablo",
  other_surnames: "Pérez",
  generation: "II",
  locale: es_aq
}

# name ; given; Rosa
# name ; given2; María
# name ; surname; Ruiz
# name ; locale; es_AQ

rosa = %PersonName{
  given_name: "Rosa",
  other_given_names: "María",
  surname: "Ruiz",
  locale: es_aq
}

# name ; given; Maria
# name ; surname; Silva
# name ; locale; pt_AQ

maria = %PersonName{
  given_name: "Maria",
  surname: "Silva",
  locale: pt_aq
}

# name ; given; 一郎
# name ; surname; 安藤
# name ; locale; ja_AQ

ichiro = %PersonName{
  given_name: "一郎",
  surname: "安藤",
  locale: ja_aq
}

# name ; given; יונתן
# name ; given2; חיים
# name ; surname; כהן
# name ; locale; he_AQ

jonathan = %PersonName{
  given_name: "יונתן",
  other_given_names: "חיים",
  surname: "כהן",
  locale: he_aq
}

# name ; given; 俊年
# name ; given2; 杰思
# name ; surname; 陈
# name ; locale; zh_AQ

pretty = %PersonName{
  given_name: "俊年",
  other_given_names: "杰思",
  surname: "陈",
  locale: zh_aq
}

# name ; title; 先生
# name ; given; 德威
# name ; given-informal; 小德
# name ; given2; 东升
# name ; surname-core; 彭
# name ; generation; 小
# name ; credentials; 议员
# name ; locale; zh_AQ

virtue = %PersonName{
  title: "先生",
  given_name: "德威",
  informal_given_name: "小德",
  other_given_names: "东升",
  surname: "彭",
  generation: "小",
  credentials: "议员",
  locale: zh_aq
}

# name ; title; 教授
# name ; given; 艾达·科妮莉亚
# name ; given-informal; 尼尔
# name ; given2; 塞萨尔·马丁
# name ; surname-prefix; 冯
# name ; surname-core; 布鲁赫
# name ; generation; 小
# name ; credentials; 博士
# name ; locale; en_AQ

ada_zh = %PersonName{
  title: "教授",
  given_name: "艾达·科妮莉亚",
  informal_given_name: "尼尔",
  other_given_names: "塞萨尔·马丁",
  surname_prefix: "冯",
  surname: "布鲁赫",
  generation: "小",
  credentials: "博士",
  locale: en_aq
}

# name ; title; Prof. Dr.
# name ; given; Ada Cornelia
# name ; given-informal; Neele
# name ; given2; César Martín
# name ; surname-prefix; von
# name ; surname-core; Brühl
# name ; surname2; González Domingo
# name ; generation; Jr
# name ; credentials; MD DDS
# name ; locale; ja_AQ

ada = %PersonName{
  title: "Prof. Dr.",
  given_name: "Ada Cornelia",
  informal_given_name: "Neele",
  other_given_names: "César Martín",
  surname_prefix: "von",
  surname: "Brühl",
  other_surnames: "González Domingo",
  generation: "Jr",
  credentials: "MD DDS",
  locale: ja_aq
}

# name ; given; Juan
# name ; given2; Luis Antonio
# name ; surname; Rodríguez Ruiz
# name ; locale; es_MX

juan = %PersonName{
  given_name: "Juan",
  other_given_names: "Luis Antonio",
  surname: "Rodríguez Ruiz",
  locale: es_mx
}

# name ; title; Sr.
# name ; given; Marcelo Miguel
# name ; given-informal; Marce
# name ; given2; Javier Ariel
# name ; surname-core; Romero
# name ; surname2; Pérez
# name ; generation; Júnior
# name ; credentials; Miembro del Parlamento
# name ; locale; es_MX

marcelo = %PersonName{
  title: "Sr.",
  given_name: "Marcelo Miguel",
  informal_given_name: "Marce",
  other_given_names: "Javier Ariel",
  surname: "Romero",
  other_surnames: "Pérez",
  generation: "Júnior",
  credentials: "Miembro del Parlamento",
  locale: es_mx
}

# name ; given; Lucía
# name ; surname; García Pérez
# name ; locale; es_US

lucia = %PersonName{
  given_name: "Lucía",
  surname: "García Pérez",
  locale: es_us
}

# name ; given; Jana
# name ; surname; Nováková
# name ; locale; cs_AQ

jana = %PersonName{
  given_name: "Jana",
  surname: "Nováková",
  locale: cs_aq
}

# name ; given; Kate
# name ; surname; Smith
# name ; locale; ko_AQ

kate = %PersonName{
  given_name: "Kate",
  surname: "Smith",
  locale: ko_aq
}

# name ; title; paní
# name ; given; Alexandra
# name ; given-informal; Saša
# name ; given2; Zuzana
# name ; surname-core; Machová
# name ; surname2; Ondřejová
# name ; generation; st.
# name ; credentials; Ph.D.
# name ; locale; cs_AQ

alexandra = %PersonName{
  title: "paní",
  given_name: "Alexandra",
  informal_given_name: "Saša",
  other_given_names: "Zuzana",
  surname: "Machová",
  other_surnames: "Ondřejová",
  generation: "st.",
  credentials: "Ph.D.",
  locale: cs_aq
}

# nativeFull
# name ; title; Bapak
# name ; given; Dwi Putro
# name ; given-informal; Dwi
# name ; given2; bin
# name ; surname-core; Adinata
# name ; credentials; MP
# name ; locale; id_AQ

dwi = %PersonName{
  title: "Bapak",
  given_name: "Dwi Putro",
  informal_given_name: "Dwi",
  other_given_names: "bin",
  surname: "Adinata",
  credentials: "MP",
  locale: id_aq
}

# name ; given; Gal·la
# name ; surname; Roig
# name ; locale; ca_AQ

gal = %PersonName{
  given_name: "Gal·la",
  surname: "Roig",
  locale: ca_aq
}

# name ; given; Jacqueline
# name ; surname; Beauchêne
# name ; locale; ko_AQ

jacqueline = %PersonName{
  given_name: "Jacqueline",
  surname: "Beauchêne",
  locale: ko_aq
}

# name ; title; Sr.
# name ; given; Josep Antoni
# name ; given-informal; Pep
# name ; given2; Carles Joan
# name ; surname-core; Lloret
# name ; surname2; Palol
# name ; generation; II
# name ; credentials; Excm.
# name ; locale; ca_AQ

josep = %PersonName{
  title: "Sr.",
  given_name: "Josep Antoni",
  informal_given_name: "Pep",
  other_given_names: "Carles Joan",
  surname: "Lloret",
  other_surnames: "Palol",
  generation: "II",
  credentials: "Excm",
  locale: ca_aq
}

# name ; given; Marie-Agnès
# name ; given2; Suzanne
# name ; surname; Gilot
# name ; locale; fr_AQ

marie_agnes = %PersonName{
  given_name: "Marie-Agnès",
  other_given_names: "Suzanne",
  surname: "Gilot",
  locale: fr_aq
}

# name ; title; Καθ. δρ.
# name ; given; Άντα Κορνέλια
# name ; given-informal; Νιλ
# name ; given2; Σέσαρ Μαρτίν
# name ; surname-prefix; φον
# name ; surname-core; Μπριλ
# name ; surname2; Γκονθάλεθ Δομίνγκο
# name ; generation; Τζούνιορ
# name ; credentials; Δρ.Ι. Δρ.Χ.Ο
# name ; locale; ja_AQ

cornelia = %PersonName{
  title: "Καθ. δρ.",
  given_name: "Άντα Κορνέλια",
  informal_given_name: "Νιλ",
  other_given_names: "Σέσαρ Μαρτίν",
  surname_prefix: "φον",
  surname: "Μπριλ",
  other_surnames: "Palol",
  generation: "Τζούνιορ",
  credentials: "Δρ.Ι. Δρ.Χ.Ο",
  locale: ja_aq
}

# foreignFull
# name ; title; Prọf. Dọk.
# name ; given; Adá Cornelia
# name ; given-informal; Néele
# name ; given2; Ẹ́va Sophia
# name ; surname-prefix; ván den
# name ; surname-core; Wólf
# name ; surname2; Bécker Schmidt
# name ; generation; jẹnereṣọn
# name ; credentials; M.D. PhD.
# name ; locale; ko_AQ

cornelia2 = %PersonName{
  title: "Prọf. Dọk.",
  given_name: "Adá Cornelia",
  informal_given_name: "Néele",
  other_given_names: "Ẹ́va Sophia",
  surname_prefix: "ván den",
  surname: "Wólf",
  other_surnames: "Bécker Schmidt",
  generation: "jẹnereṣọn",
  credentials: "M.D. PhD.",
  locale: ko_aq
}

