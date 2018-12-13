//
//  ViewController.swift
//  swiftbox
//
//  Created by hsiaosiyuan on 2018/12/13.
//  Copyright © 2018 hsiaosiyuan. All rights reserved.
//

import UIKit
import OntSwift
import Promises
import SwiftyJSON

class ViewController: UIViewController {
  var prikey1: PrivateKey?
  var address1: Address?

  var prikey2: PrivateKey?
  var address2: Address?

  let gasPrice = "0"
  let gasLimit = "20000"

  var rpc: WebsocketRpc?

  var codehash: String?
  var abi: AbiInfo?

  var ready = false

  override func viewDidLoad() {
    super.viewDidLoad()

    try! setupTestAccounts()

    rpc = WebsocketRpc(url: "ws://127.0.0.1:20335")
    rpc!.open()

    DispatchQueue.promises = .global(qos: .background)

    try! deployTestContract()
    try! loadAbi()
  }

  func setupTestAccounts() throws {
    let w = try TestWallet.w()
    prikey1 = try w.accounts[0].privateKey(pwd: "123456", params: w.scrypt)
    address1 = w.accounts[0].address

    prikey2 = try w.accounts[1].privateKey(pwd: "123456", params: w.scrypt)
    address2 = w.accounts[1].address
  }

  func loadCode() -> Data {
    let bundle = Bundle(for: type(of: self))
    let path = bundle.path(forResource: "NeoVmTests", ofType: "avm")!
    let codeBin = NSData(contentsOfFile: path)! as Data
    // some editor will insert new lines at the end of file so we trim them first
    let codeHex = String(bytes: codeBin, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let code = Data.from(hex: codeHex!)!
    codehash = Address.from(vmcode: code).toHex()
    return code
  }

  func loadAbi() throws {
    let bundle = Bundle(for: type(of: self))
    let path = bundle.path(forResource: "NeoVmTests.abi", ofType: "json")!
    let json = NSData(contentsOfFile: path)! as Data
    let abiFile = try JSONDecoder().decode(AbiFile.self, from: json)
    abi = abiFile.abi
  }

  func deployTestContract() throws {
    let code = loadCode()

    let b = TransactionBuilder()
    let tx = try b.makeDeployCodeTransaction(
      code: code as Data,
      name: "name",
      codeVersion: "1.0",
      author: "alice",
      email: "email",
      desc: "desc",
      needStorage: true,
      gasPrice: gasPrice,
      gasLimit: "30000000",
      payer: address1!
    )
    try b.sign(tx: tx, prikey: prikey1!)

    try! rpc!.send(rawTransaction: tx.serialize(), preExec: false, waitNotify: true).then {
      assert("SUCCESS" == $0["Desc"].string!)
      self.ready = true
    }
  }

  @IBAction func testName(_: Any) {
    if !ready {
      return
    }

    let fn = abi!.function(name: "name")!

    let b = TransactionBuilder()
    let tx = try! b.makeInvokeTransaction(
      fnName: fn.name,
      params: [],
      contract: Address(value: codehash!),
      gasPrice: "0",
      gasLimit: "30000000",
      payer: address1
    )
    try! b.sign(tx: tx, prikey: prikey1!)

    try! rpc!.send(rawTransaction: tx.serialize(), preExec: true).then {
      let name = String(hex: $0["Result", "Result"].string!)!
      print(name)
    }
  }

  @IBAction func testHello(_: Any) {
    if !ready {
      return
    }

    let fn = abi!.function(name: "hello")!

    let b = TransactionBuilder()

    let tx = try! b.makeInvokeTransaction(
      fnName: fn.name,
      params: [
        "world".abiParameter(name: "msg"),
      ],
      contract: Address(value: codehash!),
      gasPrice: "0",
      gasLimit: "30000000",
      payer: address1
    )
    try! b.sign(tx: tx, prikey: prikey1!)

    try! rpc!.send(rawTransaction: tx.serialize(), preExec: true).then {
      let msg = String(hex: $0["Result", "Result"].string!)!
      print(msg)
    }
  }

  @IBAction func testTrue() {
    if !ready {
      return
    }

    let fn = abi!.function(name: "testTrue")!

    let b = TransactionBuilder()

    let tx = try! b.makeInvokeTransaction(
      fnName: fn.name,
      params: [],
      contract: Address(value: codehash!),
      gasPrice: "0",
      gasLimit: "30000000",
      payer: address1
    )
    try! b.sign(tx: tx, prikey: prikey1!)

    try! rpc!.send(rawTransaction: tx.serialize(), preExec: true).then {
      let ret = Bool(hex: $0["Result", "Result"].string!)
      print(ret)
    }
  }

  @IBAction func testFalse() {
    if !ready {
      return
    }

    let fn = abi!.function(name: "testFalse")!

    let b = TransactionBuilder()

    let tx = try! b.makeInvokeTransaction(
      fnName: fn.name,
      params: [],
      contract: Address(value: codehash!),
      gasPrice: "0",
      gasLimit: "30000000",
      payer: address1
    )
    try! b.sign(tx: tx, prikey: prikey1!)

    try! rpc!.send(rawTransaction: tx.serialize(), preExec: true).then {
      let ret = Bool(hex: $0["Result", "Result"].string!)
      print(ret)
    }
  }

  @IBAction func testList() throws {
    if !ready {
      return
    }

    let fn = abi!.function(name: "testHello")!

    let b = TransactionBuilder()

    let contract = try Address(value: codehash!)

    let tx = try b.makeInvokeTransaction(
      fnName: fn.name,
      params: [
        false.abiParameter(name: "msgBool"),
        300.abiParameter(name: "msgInt"),
        Data(bytes: [1, 2, 3]).abiParameter(name: "msgByteArray"),
        "string".abiParameter(name: "msgStr"),
        contract.abiParameter(name: "msgAddress"),
      ],
      contract: contract,
      gasPrice: "0",
      gasLimit: "30000000",
      payer: address1
    )
    try b.sign(tx: tx, prikey: prikey1!)

    try! rpc!.send(rawTransaction: tx.serialize(), preExec: true).then {
      let bool = Bool(hex: $0["Result", "Result", 0].string!)
      let int = Int(hex: $0["Result", "Result", 1].string!)
      let data = Data.from(hex: $0["Result", "Result", 2].string!)!
      let str = String(hex: $0["Result", "Result", 3].string!)!
      let addr = Data.from(hex: $0["Result", "Result", 4].string!)!

      print(bool)
      print(int)
      print(data)
      print(str)
      print(addr)
    }
  }

  @IBAction func testStruct() {
    if !ready {
      return
    }

    let fn = abi!.function(name: "testStructList")!

    let b = TransactionBuilder()

    let contract = try! Address(value: codehash!)

    let structure = Struct()
    structure.add(params: 100, "claimid".data(using: .utf8)!)

    let tx = try! b.makeInvokeTransaction(
      fnName: fn.name,
      params: [
        structure.abiParameter(name: "structList"),
      ],
      contract: contract,
      gasPrice: "0",
      gasLimit: "30000000",
      payer: address1
    )
    try! b.sign(tx: tx, prikey: prikey1!)

    try! rpc!.send(rawTransaction: tx.serialize(), preExec: true).then {
      let s = Struct(hex: $0["Result", "Result"].string!)
      let f1 = s.list[0] as! Struct.RawField
      let f2 = s.list[1] as! Struct.RawField

      let int = BigInt(f1.bytes).int64!
      let str = String(bytes: f2.bytes, encoding: .utf8)!

      print(int)
      print(str)
    }
  }

  func setMap() -> Promise<Void> {
    let fn = abi!.function(name: "testMap")!

    let b = TransactionBuilder()

    let contract = try! Address(value: codehash!)

    let map = [
      "key": "value".abiParameter(),
    ].abiParameter(name: "msg")

    let tx = try! b.makeInvokeTransaction(
      fnName: fn.name,
      params: [map],
      contract: contract,
      gasPrice: "0",
      gasLimit: "30000000",
      payer: address1
    )
    try! b.sign(tx: tx, prikey: prikey1!)

    // here we want to change the storage so the `preExec` flag SHOULD be false
    return try! rpc!.send(rawTransaction: tx.serialize(), preExec: false, waitNotify: true).then {
      assert("SUCCESS" == $0["Desc"].string)
    }
  }

  func getMap() -> Promise<Any> {
    let fn = abi!.function(name: "testGetMap")!

    let b = TransactionBuilder()

    let contract = try! Address(value: codehash!)

    let tx = try! b.makeInvokeTransaction(
      fnName: fn.name,
      params: [
        "key".abiParameter(name: "key"),
      ],
      contract: contract,
      gasPrice: "0",
      gasLimit: "30000000",
      payer: address1
    )
    try! b.sign(tx: tx, prikey: prikey1!)

    return try! rpc!.send(rawTransaction: tx.serialize(), preExec: true).then {
      let value = String(hex: $0["Result", "Result"].string!)!
      print(value)
      return Promise<Any>(0)
    }
  }

  @IBAction func testMap() {
    if !ready {
      return
    }

    _ = Promise<Void> {
      _ = try! await(self.setMap())
      _ = try! await(self.getMap())
    }
  }

  func setMapInMap() -> Promise<Void> {
    let fn = abi!.function(name: "testMapInMap")!

    let b = TransactionBuilder()

    let contract = try! Address(value: codehash!)

    let map = [
      "key": [
        "key": "value".abiParameter(),
      ].abiParameter(),
    ].abiParameter(name: "msg")

    let tx = try! b.makeInvokeTransaction(
      fnName: fn.name,
      params: [map],
      contract: contract,
      gasPrice: "0",
      gasLimit: "30000000",
      payer: address1
    )
    try! b.sign(tx: tx, prikey: prikey1!)

    // here we want to change the storage so the `preExec` flag SHOULD be false
    return try! rpc!.send(rawTransaction: tx.serialize(), preExec: false, waitNotify: true).then {
      assert("SUCCESS" == $0["Desc"].string!)
    }
  }

  func getMapInMap() -> Promise<Any> {
    let fn = abi!.function(name: "testGetMapInMap")!

    let b = TransactionBuilder()

    let contract = try! Address(value: codehash!)

    let tx = try! b.makeInvokeTransaction(
      fnName: fn.name,
      params: [
        "key".abiParameter(name: "key"),
      ],
      contract: contract,
      gasPrice: "0",
      gasLimit: "30000000",
      payer: address1
    )
    try! b.sign(tx: tx, prikey: prikey1!)

    return try! rpc!.send(rawTransaction: tx.serialize(), preExec: true).then {
      let value = String(hex: $0["Result", "Result"].string!)!
      print(value)
      return Promise<Any>(0)
    }
  }

  @IBAction func testMapInMap() {
    if !ready {
      return
    }

    _ = Promise<Void> {
      _ = try! await(self.setMapInMap())
      _ = try! await(self.getMapInMap())
    }
  }
}
