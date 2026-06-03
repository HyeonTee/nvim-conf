; extends

; Prisma raw query 등 태그드 템플릿 안의 SQL 하이라이팅
; 예) prisma.$queryRaw`...`, tx.$executeRaw<T>`...`, Prisma.sql`...`
((call_expression
   function: (member_expression
     property: (property_identifier) @_method)
   arguments: (template_string) @injection.content)
 (#any-of? @_method
   "$queryRaw" "$executeRaw"
   "$queryRawTyped"
   "sql" "raw" "unsafe")
 (#set! injection.language "sql"))

; bare 태그드 템플릿: sql`...`, SQL`...`
((call_expression
   function: (identifier) @_fn
   arguments: (template_string) @injection.content)
 (#any-of? @_fn "sql" "SQL")
 (#set! injection.language "sql"))

; 함수 호출 + 템플릿/문자열 인자: $queryRawUnsafe(`...`), $executeRawUnsafe(`...`)
((call_expression
   function: (member_expression
     property: (property_identifier) @_method)
   arguments: (arguments (template_string) @injection.content))
 (#any-of? @_method "$queryRawUnsafe" "$executeRawUnsafe")
 (#set! injection.language "sql"))
