## Test file for new Nimini features:
## 1. Named parameters in function calls
## 2. Object constructors with field initializers
## 3. Result variable in procs

type
  Vector2 = object
    x: float32
    y: float32

  Person = object
    name: string
    age: int

# Test 1: Named parameters
proc greet(name: string; age: int): string =
  "Hello " & name & ", you are " & $age & " years old"

# Test 2: Result variable
proc addNumbers(a: int; b: int): int =
  result = a + b
  result = result * 2  # Modify result

proc createVector(x: float32; y: float32): Vector2 =
  result.x = x
  result.y = y

# Test 3: Object constructor
proc makeVector(x: float32; y: float32): Vector2 =
  Vector2(x: x, y: y)

proc makePerson(name: string; age: int): Person =
  Person(name: name, age: age)

proc main() =
  # Test named parameters in function call
  echo greet(name = "Alice", age = 30)
  echo greet(age = 25, name = "Bob")  # Different order
  
  # Test result variable
  let sum = addNumbers(5, 3)  # Should be (5+3)*2 = 16
  echo "Sum: ", sum
  
  # Test result with object
  let v1 = createVector(10.0, 20.0)
  echo "V1: x=", v1.x, " y=", v1.y
  
  # Test object constructor
  let v2 = makeVector(5.0, 15.0)
  echo "V2: x=", v2.x, " y=", v2.y
  
  let p = makePerson("Charlie", 35)
  echo "Person: ", p.name, " is ", p.age

when isMainModule:
  main()
