//
//  ViewController.swift
//  To_Do_List
//
//  Created by 박형환 on 2021/11/08.
//

import UIKit



class ViewController: UIViewController {

    @IBOutlet weak var tableVIew: UITableView!
    @IBOutlet var editButton: UIBarButtonItem!
    var doneButton: UIBarButtonItem?
    var task: [TasK] = [] {
        didSet {
            self.saveTasks()
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapDoneButton))
        self.tableVIew.dataSource = self
        self.tableVIew.delegate = self
        
        //롱프레스 제스쳐 추가해서 테이블뷰에 addGesture해주기
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressCalled(_:)))
        self.tableVIew.addGestureRecognizer(longPressGesture)
        
        self.loadTasks()
    }
    
    //long click 했을때의 스냅샷 이미지 만들기
    func snapnshotOfcell(_ inputView: UIView) -> UIView {
        // Begin Image context
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()! as UIImage
        UIGraphicsEndImageContext()
        
        let cellSnapshot: UIView = UIImageView(image: image)
        cellSnapshot.layer.masksToBounds = false //기본값 false
        cellSnapshot.layer.cornerRadius = 0.0
        cellSnapshot.layer.shadowOffset = CGSize(width: -5.0, height: 0.0)
        cellSnapshot.layer.shadowRadius = 5.0
        cellSnapshot.layer.shadowOpacity = 0.4
        return cellSnapshot
    }
    
    
    //롱클릭 했을때 불려지는 롱프레스콜드 함수
    @objc func longPressCalled(_ longPress: UILongPressGestureRecognizer){
        print("longPressCalled")
        
        let locationInView = longPress.location(in: self.tableVIew)
        let indexPath = self.tableVIew.indexPathForRow(at: locationInView)
        
        
        struct My{
            static var cellSnapshot: UIView?
        }
        struct Path{
            static var initialIndexPath: IndexPath?
        }
        
        switch longPress.state {
        case UIGestureRecognizer.State.began:
            print("began")
            guard let indexPath = indexPath else {return}
            guard let cell = self.tableVIew.cellForRow(at: indexPath) else {return}
            Path.initialIndexPath = indexPath
            My.cellSnapshot = snapnshotOfcell(cell)
       
            var center = cell.center
            My.cellSnapshot!.center = center
            My.cellSnapshot!.alpha = 0.0
            self.tableVIew.addSubview(My.cellSnapshot!)
            
            UIView.animate(withDuration: 0.25,
                           animations:
                            { () -> Void in
                                center.y = locationInView.y
                                My.cellSnapshot!.center = center
                                My.cellSnapshot!.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                                My.cellSnapshot!.alpha = 0.98
                                cell.alpha = 0.0
                            },
                            completion:
                            {(finished) -> Void in
                            if finished {
                                cell.isHidden = true
                            }
                    }
            )
         case UIGestureRecognizer.State.changed:
            print("touch changed")
            
            var center = My.cellSnapshot!.center
            center.y = locationInView.y
            My.cellSnapshot!.center = center
            
            if((indexPath != nil) && (indexPath != Path.initialIndexPath)){
                let exchangeTask = self.task[indexPath!.row]
                self.task[indexPath!.row] = self.task[Path.initialIndexPath!.row]
                self.task[Path.initialIndexPath!.row] = exchangeTask
                
                self.tableVIew.moveRow(at: Path.initialIndexPath!, to: indexPath!)
                Path.initialIndexPath = indexPath
            }
            
         default:
            print("finished")
            guard let cell = self.tableVIew.cellForRow(at: Path.initialIndexPath!) else {return}
            cell.isHidden = false
            cell.alpha = 0.0
            
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                My.cellSnapshot!.center = cell.center
                My.cellSnapshot!.transform = CGAffineTransform.identity
                My.cellSnapshot!.alpha = 0.0
                cell.alpha = 1.0
           
            }, completion: { (finished) -> Void in
                if finished {
                    Path.initialIndexPath = nil
                    My.cellSnapshot!.removeFromSuperview()
                    My.cellSnapshot = nil
                }
            })
        }
    }
  
    @objc func tapDoneButton() {
        self.navigationItem.leftBarButtonItem = self.editButton
        self.tableVIew.setEditing(false, animated: true)
        
    }
    
    @IBAction func tapEditButton(_ sender: UIBarButtonItem) {
        guard !self.task.isEmpty else{return}
        self.navigationItem.leftBarButtonItem = self.doneButton
        self.tableVIew.setEditing(true, animated: true)
    }
    
    @IBAction func tapAddButton(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "할 일 등록", message: nil, preferredStyle: .alert)
        let register = UIAlertAction(title: "등록", style: .default, handler: {
          [weak self]  _ in
            guard let title = alert.textFields?[0].text else {return}
            guard let subTitle = alert.textFields?[1].text else {return}
            let task = TasK(title: title,subTitle: subTitle, done: false)
            self?.task.append(task)
            print("추가")
            self?.tableVIew.reloadData()
            print("갱신")
        })
        
        let cancel = UIAlertAction(title: "취소", style: .default, handler: nil)
        alert.addAction(register)
        alert.addAction(cancel)
        alert.addTextField(configurationHandler: {
            textField in
            textField.placeholder = "제목을 등록해주세요"
        })
        alert.addTextField(configurationHandler: {
            $0.placeholder = "할 일을 입력해주세요"
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveTasks() {
        print("saveTask call")
        let data = self.task.map { key in
            [
             "title" : key.title,
             "subTitle" : key.subTitle,
              "done" : key.done
            ]
        }
        let userDefaults = UserDefaults.standard
        userDefaults.set(data, forKey: "tasks")
       
    }
    func loadTasks() {
        print("loadTask call")
        let userDefaults = UserDefaults.standard
        guard let data = userDefaults.object(forKey: "tasks") as? [[String : Any]] else {return}
        self.task = data.compactMap{ key in
            guard let title = key["title"] as? String else {return nil}
            guard let subTitle = key["subTitle"] as? String else {return nil}
            guard let done = key["done"] as? Bool else {return nil}
            return TasK(title: title, subTitle: subTitle, done: done)
        }
    }
}

extension ViewController: UITableViewDataSource{
    //각 세션에 표시할 행의 갯수
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("numberofRowInsection call")
        print("\(section)")
        return self.task.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //dequeueReuableCell
        //10 1000 10000000 각각만들어 할당을 하면 메모리 낭비 가 심해진다 앱이 멈추거나 비정상적인
        //이 메서드는 셀을 재사용 할수 있게 한다.
        print("cellforRowAt dequeueReusableCell 호출")
        print("\(indexPath)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        

        let task = self.task[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.attributedText = NSAttributedString(string: task.title, attributes:[
            .font: UIFont.systemFont(ofSize: 30, weight: .bold),
            .foregroundColor: UIColor.systemBlue
        ])
        content.secondaryAttributedText = NSAttributedString(string: task.subTitle, attributes:[
            .font : UIFont.systemFont(ofSize: 20, weight: .heavy),
            .foregroundColor : UIColor.systemOrange,
            .backgroundColor : UIColor.systemGray
        ])
        content.textProperties.alignment = .justified
        content.secondaryTextProperties.alignment = .justified
        
        var backgroundConfig = UIBackgroundConfiguration.listPlainCell()
        backgroundConfig.backgroundColor = .lightGray
        backgroundConfig.cornerRadius = 10
        backgroundConfig.backgroundInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        backgroundConfig.strokeColor = .systemPurple
        backgroundConfig.strokeWidth = 1
        cell.backgroundConfiguration = backgroundConfig
        cell.contentConfiguration = content

        
        // 할일 버튼 클릭시 체크버튼 표시 done 의 true false 값에 따라
        if task.done {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    
    
    
    // 테이블뷰의 에디팅 모드 set 되었을때 task 의 항목을 지우고 테이블 뷰의 indexpath 경로 값으로 항목을 지운다
    // task 의 값이 비었으면 edit 모드 끝내기
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        self.task.remove(at: indexPath.row)
        self.tableVIew.deleteRows(at: [indexPath], with: .automatic)
        if self.task.isEmpty {
            self.tapDoneButton()
        }
    }

    //edit mode 가 setting 되면
    //table 뷰의 각 항목을 옮길 수가 있게 true return
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    //tableView 의 soureIndexPath 는 옮기기전 항목의 인덱스
    // destinationIndexPath 는 옮기고 난 후의 인덱스
    //옮길때 task 의 항목을 삭제 하고 insert해서
    // task 의 프로퍼티 옵저버 호출 didset saveTask 두번 호출
  
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let data = self.task[sourceIndexPath.row]
        self.task.remove(at: sourceIndexPath.row)
        self.task.insert(data, at: destinationIndexPath.row)
    }
}


extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("click")
        var task = self.task[indexPath.row]
        task.done = !task.done
        self.task[indexPath.row] = task
        self.tableVIew.reloadRows(at: [indexPath], with: .automatic)
    }
}





